# frozen_string_literal: true

# Integration test suite for SSH connectivity
#
# This test suite validates SSH information retrieval and integration with SSHReadinessChecker.
# Tests verify the provider's ssh_info method returns correct connection parameters for
# OrbStack's SSH proxy architecture.
#
# NOTE: These tests mock OrbStackCLI calls to avoid requiring actual OrbStack installation.
# For real SSH connectivity tests with actual OrbStack, see spec/e2e/vagrant_ssh_spec.rb.
#
# Expected behavior:
# - ssh_info returns nil when machine is not created or stopped
# - ssh_info returns correct hash when machine is running
# - Hash includes OrbStack SSH proxy configuration (127.0.0.1:32222)
# - Create action integrates with SSHReadinessChecker.wait_for_ready
# - SSH configuration includes machine ID as username for proxy routing

require 'spec_helper'

RSpec.describe 'SSH Connectivity Integration' do
  # ============================================================================
  # SSH_INFO METHOD TESTS
  # ============================================================================

  describe 'Provider#ssh_info' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:ui) do
      double('ui',
             info: nil,
             warn: nil,
             error: nil,
             success: nil,
             ask: nil)
    end

    let(:provider_config) do
      double('provider_config',
             distro: 'ubuntu',
             version: 'noble',
             forward_agent: false)
    end

    let(:machine) do
      double('machine',
             name: 'default',
             id: 'vagrant-default-a3b2c1',
             provider_config: provider_config,
             ui: ui,
             data_dir: Pathname.new('/tmp/vagrant-ssh-test'))
    end

    let(:provider) do
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    after do
      FileUtils.rm_rf('/tmp/vagrant-ssh-test')
    end

    context 'when machine state is :running' do
      it 'returns correct SSH connection hash' do
        # Arrange
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([{
                        name: 'vagrant-default-a3b2c1',
                        status: 'running'
                      }])

        # Act
        ssh_info = provider.ssh_info

        # Assert
        expect(ssh_info).to be_a(Hash)
        expect(ssh_info[:host]).to eq('127.0.0.1')
        expect(ssh_info[:port]).to eq(32_222)
        expect(ssh_info[:username]).to eq('vagrant-default-a3b2c1')
        expect(ssh_info[:private_key_path]).to eq(File.expand_path('~/.orbstack/ssh/id_ed25519'))
        expect(ssh_info[:forward_agent]).to eq(false)
      end

      it 'includes proxy_command for OrbStack SSH proxy' do
        # Arrange
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([{
                        name: 'vagrant-default-a3b2c1',
                        status: 'running'
                      }])

        # Act
        ssh_info = provider.ssh_info

        # Assert
        expect(ssh_info).to have_key(:proxy_command)
        expect(ssh_info[:proxy_command]).to include('OrbStack Helper')
        expect(ssh_info[:proxy_command]).to include('ssh-proxy-fdpass')
      end

      it 'uses machine ID as username for proxy routing' do
        # Arrange
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([{
                        name: 'vagrant-default-a3b2c1',
                        status: 'running'
                      }])

        # Act
        ssh_info = provider.ssh_info

        # Assert - username matches machine ID for OrbStack proxy routing
        expect(ssh_info[:username]).to eq(machine.id)
      end

      it 'respects forward_agent configuration setting' do
        # Arrange
        custom_config = double('provider_config',
                               distro: 'ubuntu',
                               version: 'noble',
                               forward_agent: true)
        custom_machine = double('machine',
                                name: 'default',
                                id: 'vagrant-default-a3b2c1',
                                provider_config: custom_config,
                                ui: ui,
                                data_dir: Pathname.new('/tmp/vagrant-ssh-test'))
        custom_provider = VagrantPlugins::OrbStack::Provider.new(custom_machine)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([{
                        name: 'vagrant-default-a3b2c1',
                        status: 'running'
                      }])

        # Act
        ssh_info = custom_provider.ssh_info

        # Assert
        expect(ssh_info[:forward_agent]).to eq(true)
      end
    end

    context 'when machine state is :stopped' do
      it 'returns nil' do
        # Arrange
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([{
                        name: 'vagrant-default-a3b2c1',
                        status: 'stopped'
                      }])

        # Act
        ssh_info = provider.ssh_info

        # Assert
        expect(ssh_info).to be_nil
      end
    end

    context 'when machine state is :not_created' do
      it 'returns nil when machine ID is nil' do
        # Arrange
        machine_without_id = double('machine',
                                    name: 'default',
                                    id: nil,
                                    provider_config: provider_config,
                                    ui: ui,
                                    data_dir: Pathname.new('/tmp/vagrant-ssh-test'))
        provider_without_id = VagrantPlugins::OrbStack::Provider.new(machine_without_id)

        # Act
        ssh_info = provider_without_id.ssh_info

        # Assert
        expect(ssh_info).to be_nil
      end

      it 'returns nil when machine does not exist in OrbStack' do
        # Arrange
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([]) # Machine not found in OrbStack

        # Act
        ssh_info = provider.ssh_info

        # Assert
        expect(ssh_info).to be_nil
      end
    end

    context 'SSH configuration values' do
      before do
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([{
                        name: 'vagrant-default-a3b2c1',
                        status: 'running'
                      }])
      end

      it 'always uses 127.0.0.1 as host (OrbStack proxy, not VM IP)' do
        # Arrange & Act
        ssh_info = provider.ssh_info

        # Assert - CRITICAL: Must use proxy host, not VM IP
        expect(ssh_info[:host]).to eq('127.0.0.1')
      end

      it 'always uses port 32222 (OrbStack SSH proxy port)' do
        # Arrange & Act
        ssh_info = provider.ssh_info

        # Assert - CRITICAL: Must use proxy port, not standard SSH port 22
        expect(ssh_info[:port]).to eq(32_222)
      end

      it 'uses OrbStack auto-generated ED25519 key' do
        # Arrange & Act
        ssh_info = provider.ssh_info

        # Assert
        expect(ssh_info[:private_key_path]).to end_with('.orbstack/ssh/id_ed25519')
      end
    end
  end

  # ============================================================================
  # SSH READINESS CHECKER INTEGRATION TESTS
  # ============================================================================

  describe 'SSHReadinessChecker integration with Create action' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/create'
      require 'vagrant-orbstack/util/machine_namer'
      require 'vagrant-orbstack/util/ssh_readiness_checker'
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:ui) do
      double('ui',
             info: nil,
             warn: nil,
             error: nil,
             success: nil)
    end

    let(:provider_config) do
      double('provider_config',
             distro: 'ubuntu',
             version: 'noble')
    end

    let(:machine) do
      double('machine',
             name: 'default',
             id: nil,
             provider_config: provider_config,
             ui: ui,
             data_dir: Pathname.new('/tmp/vagrant-ssh-integration-test'))
    end

    let(:provider) do
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    after do
      FileUtils.rm_rf('/tmp/vagrant-ssh-integration-test')
    end

    it 'Create action calls SSHReadinessChecker.wait_for_ready after creating machine' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)
      allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([])
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
        .with('vagrant-default-a3b2c1', distribution: 'ubuntu:noble')
        .and_return({
                      id: 'vagrant-default-a3b2c1',
                      name: 'vagrant-default-a3b2c1',
                      status: 'running'
                    })

      # Assert - expect SSHReadinessChecker to be called
      expect(VagrantPlugins::OrbStack::Util::SSHReadinessChecker)
        .to receive(:wait_for_ready)
        .with('vagrant-default-a3b2c1', ui: ui)

      # Act
      action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      action.call({ machine: machine, ui: ui })
    end

    it 'Create action calls SSHReadinessChecker.wait_for_ready after starting stopped machine' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)
      allow(machine).to receive(:id).and_return('vagrant-default-a3b2c1')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([{
                      name: 'vagrant-default-a3b2c1',
                      status: 'stopped'
                    }])
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
        .with('vagrant-default-a3b2c1')
        .and_return({
                      id: 'vagrant-default-a3b2c1',
                      status: 'running'
                    })

      # Assert - expect SSHReadinessChecker to be called
      expect(VagrantPlugins::OrbStack::Util::SSHReadinessChecker)
        .to receive(:wait_for_ready)
        .with('vagrant-default-a3b2c1', ui: ui)

      # Act
      action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      action.call({ machine: machine, ui: ui })
    end

    it 'does not call SSHReadinessChecker.wait_for_ready when machine is already running' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)
      allow(machine).to receive(:id).and_return('vagrant-default-a3b2c1')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([{
                      name: 'vagrant-default-a3b2c1',
                      status: 'running'
                    }])

      # Assert - should NOT call SSHReadinessChecker for already-running machine
      expect(VagrantPlugins::OrbStack::Util::SSHReadinessChecker)
        .not_to receive(:wait_for_ready)

      # Act
      action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      action.call({ machine: machine, ui: ui })
    end
  end

  # ============================================================================
  # MULTI-MACHINE SSH CONFIGURATION TESTS
  # ============================================================================

  describe 'Multi-machine SSH configuration' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:ui) do
      double('ui',
             info: nil,
             warn: nil,
             error: nil)
    end

    let(:provider_config) do
      double('provider_config',
             distro: 'ubuntu',
             version: 'noble',
             forward_agent: false)
    end

    after do
      FileUtils.rm_rf('/tmp/vagrant-ssh-multi-test-web')
      FileUtils.rm_rf('/tmp/vagrant-ssh-multi-test-db')
    end

    it 'each machine has unique SSH username matching its machine ID' do
      # Arrange - web machine
      web_machine = double('machine',
                           name: 'web',
                           id: 'vagrant-web-a1b2c3',
                           provider_config: provider_config,
                           ui: ui,
                           data_dir: Pathname.new('/tmp/vagrant-ssh-multi-test-web'))
      web_provider = VagrantPlugins::OrbStack::Provider.new(web_machine)

      # Arrange - db machine
      db_machine = double('machine',
                          name: 'db',
                          id: 'vagrant-db-d4e5f6',
                          provider_config: provider_config,
                          ui: ui,
                          data_dir: Pathname.new('/tmp/vagrant-ssh-multi-test-db'))
      db_provider = VagrantPlugins::OrbStack::Provider.new(db_machine)

      # Mock running state for both
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([
                      { name: 'vagrant-web-a1b2c3', status: 'running' },
                      { name: 'vagrant-db-d4e5f6', status: 'running' }
                    ])

      # Act
      web_ssh_info = web_provider.ssh_info
      db_ssh_info = db_provider.ssh_info

      # Assert - usernames are unique and match machine IDs
      expect(web_ssh_info[:username]).to eq('vagrant-web-a1b2c3')
      expect(db_ssh_info[:username]).to eq('vagrant-db-d4e5f6')
      expect(web_ssh_info[:username]).not_to eq(db_ssh_info[:username])
    end

    it 'all machines use same SSH proxy host and port' do
      # Arrange - web machine
      web_machine = double('machine',
                           name: 'web',
                           id: 'vagrant-web-a1b2c3',
                           provider_config: provider_config,
                           ui: ui,
                           data_dir: Pathname.new('/tmp/vagrant-ssh-multi-test-web'))
      web_provider = VagrantPlugins::OrbStack::Provider.new(web_machine)

      # Arrange - db machine
      db_machine = double('machine',
                          name: 'db',
                          id: 'vagrant-db-d4e5f6',
                          provider_config: provider_config,
                          ui: ui,
                          data_dir: Pathname.new('/tmp/vagrant-ssh-multi-test-db'))
      db_provider = VagrantPlugins::OrbStack::Provider.new(db_machine)

      # Mock running state for both
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([
                      { name: 'vagrant-web-a1b2c3', status: 'running' },
                      { name: 'vagrant-db-d4e5f6', status: 'running' }
                    ])

      # Act
      web_ssh_info = web_provider.ssh_info
      db_ssh_info = db_provider.ssh_info

      # Assert - all machines share same proxy endpoint
      expect(web_ssh_info[:host]).to eq('127.0.0.1')
      expect(db_ssh_info[:host]).to eq('127.0.0.1')
      expect(web_ssh_info[:port]).to eq(32_222)
      expect(db_ssh_info[:port]).to eq(32_222)
    end
  end
end
