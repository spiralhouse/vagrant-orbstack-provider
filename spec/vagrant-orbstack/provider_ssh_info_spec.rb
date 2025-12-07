# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Provider#ssh_info
#
# This test verifies that the Provider#ssh_info method correctly returns
# SSH connection parameters for Vagrant to connect to OrbStack machines.
#
# CRITICAL: OrbStack uses SSH proxy architecture, NOT direct SSH to VM IP!
#
# Expected behavior (based on OrbStack SSH proxy architecture):
# - Returns hash with :host, :port, :username, :private_key_path, :forward_agent
# - Host MUST be '127.0.0.1' (localhost proxy, NOT VM IP address)
# - Port MUST be 32222 (OrbStack SSH proxy port, NOT 22)
# - Username MUST be machine ID (for proxy routing, NOT ssh_username config)
# - private_key_path MUST be ~/.orbstack/ssh/id_ed25519 (expanded path)
# - forward_agent uses configured value (default false)
# - Returns nil when machine state is :not_created or :stopped
# - Returns nil when machine info unavailable
#
# Reference: SPI-1225 - Provider#ssh_info implementation
# Reference: docs/DESIGN.md lines 600-764 - SSH Proxy Architecture

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Provider#ssh_info' do
  # Mock Vagrant machine object for testing
  let(:ui) do
    double('ui').tap do |ui|
      allow(ui).to receive(:warn)
      allow(ui).to receive(:error)
    end
  end

  let(:provider_config) do
    double('config').tap do |config|
      allow(config).to receive(:ssh_username).and_return(nil)
      allow(config).to receive(:forward_agent).and_return(false)
    end
  end

  let(:machine) do
    double('machine',
           name: 'default',
           provider_config: provider_config,
           data_dir: Pathname.new('/tmp/vagrant-test'),
           ui: ui,
           id: 'test-machine-id')
  end

  let(:provider) do
    require 'vagrant-orbstack/provider'
    VagrantPlugins::OrbStack::Provider.new(machine)
  end

  # ============================================================================
  # PROVIDER#SSH_INFO TESTS (SPI-1225)
  # ============================================================================
  #
  # These tests verify that the Provider#ssh_info method correctly returns
  # SSH connection parameters based on OrbStack machine state and configuration.
  #
  # Reference: SPI-1225 - Provider#ssh_info implementation
  # ============================================================================

  describe '#ssh_info' do
    context 'when machine state is :not_created' do
      it 'returns nil' do
        # Arrange
        not_created_state = Vagrant::MachineState.new(
          :not_created,
          'not created',
          'Machine does not exist in OrbStack'
        )
        allow(provider).to receive(:state).and_return(not_created_state)

        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_nil
      end
    end

    context 'when machine state is :stopped' do
      it 'returns nil' do
        # Arrange
        stopped_state = Vagrant::MachineState.new(
          :stopped,
          'stopped',
          'Machine is stopped'
        )
        allow(provider).to receive(:state).and_return(stopped_state)

        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_nil
      end
    end

    context 'when machine is running' do
      let(:running_state) do
        Vagrant::MachineState.new(
          :running,
          'running',
          'Machine is running in OrbStack'
        )
      end

      before do
        allow(provider).to receive(:state).and_return(running_state)
      end

      # ========================================================================
      # CRITICAL: SSH PROXY ARCHITECTURE TESTS
      # ========================================================================
      # OrbStack uses localhost:32222 SSH proxy, NOT direct SSH to VM IP
      # Reference: docs/DESIGN.md lines 600-764
      # ========================================================================

      it 'returns hash with :host as 127.0.0.1 (localhost proxy, NOT VM IP)' do
        # Arrange - OrbStack SSH proxy requires localhost, NOT VM IP address
        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_a(Hash)
        expect(result[:host]).to eq('127.0.0.1'),
                                 'OrbStack uses SSH proxy at localhost, NOT direct SSH to VM IP'
      end

      it 'returns hash with :port as 32222 (OrbStack SSH proxy port, NOT 22)' do
        # Arrange - OrbStack SSH proxy listens on port 32222, NOT 22
        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_a(Hash)
        expect(result[:port]).to eq(32_222),
                                 'OrbStack SSH proxy listens on port 32222, NOT standard SSH port 22'
      end

      it 'returns hash with :username as machine ID (for proxy routing)' do
        # Arrange - OrbStack proxy uses machine ID for routing, NOT ssh_username
        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_a(Hash)
        expect(result[:username]).to eq('test-machine-id'),
                                     'OrbStack SSH proxy requires machine ID as username for routing'
      end

      it 'returns hash with :private_key_path as ~/.orbstack/ssh/id_ed25519 (expanded)' do
        # Arrange - OrbStack uses auto-generated ED25519 key
        expected_path = File.expand_path('~/.orbstack/ssh/id_ed25519')

        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_a(Hash)
        expect(result[:private_key_path]).to eq(expected_path),
                                             'OrbStack SSH uses auto-generated ED25519 key'
      end

      context 'when forward_agent is configured as true' do
        before do
          allow(provider_config).to receive(:forward_agent).and_return(true)
        end

        it 'returns hash with :forward_agent as true' do
          # Act
          result = provider.ssh_info

          # Assert
          expect(result).to be_a(Hash)
          expect(result[:forward_agent]).to eq(true)
        end
      end

      context 'when forward_agent is configured as false' do
        before do
          allow(provider_config).to receive(:forward_agent).and_return(false)
        end

        it 'returns hash with :forward_agent as false' do
          # Act
          result = provider.ssh_info

          # Assert
          expect(result).to be_a(Hash)
          expect(result[:forward_agent]).to eq(false)
        end
      end

      # ========================================================================
      # CRITICAL: ProxyCommand Required for OrbStack SSH Connectivity
      # ========================================================================
      # OrbStack SSH requires ProxyCommand to route through OrbStack Helper app
      # Without proxy_command, direct SSH to localhost:32222 fails with:
      # "Host key verification failed"
      #
      # Reference: /tmp/SPI-1225-live-test-findings.md
      # Reference: ~/.orbstack/ssh/config - ProxyCommand configuration
      # ========================================================================

      it 'returns hash with :proxy_command pointing to OrbStack Helper' do
        # Arrange
        expected_helper_path = '/Applications/OrbStack.app/Contents/Frameworks/' \
                               'OrbStack Helper.app/Contents/MacOS/OrbStack Helper'

        # Act
        result = provider.ssh_info

        # Assert - ProxyCommand must be present
        expect(result[:proxy_command]).not_to be_nil,
                                              'OrbStack SSH requires ProxyCommand to route through OrbStack Helper'
        expect(result[:proxy_command]).not_to be_empty,
                                              'OrbStack SSH ProxyCommand must not be empty'

        # Assert - ProxyCommand must invoke OrbStack Helper app
        expect(result[:proxy_command]).to include('OrbStack Helper'),
                                          'ProxyCommand must invoke OrbStack Helper app'

        # Assert - ProxyCommand must use ssh-proxy-fdpass protocol
        expect(result[:proxy_command]).to include('ssh-proxy-fdpass'),
                                          'ProxyCommand must use ssh-proxy-fdpass protocol for OrbStack routing'

        # Assert - ProxyCommand must include current user UID for routing
        expect(result[:proxy_command]).to include(Process.uid.to_s),
                                          "ProxyCommand must include current user UID (#{Process.uid}) for routing"

        # Assert - ProxyCommand should match OrbStack's expected format
        expected_proxy_command = "'#{expected_helper_path}' ssh-proxy-fdpass #{Process.uid}"
        expect(result[:proxy_command]).to eq(expected_proxy_command),
                                          "ProxyCommand must match OrbStack's format: '#{expected_proxy_command}'"
      end

      # ========================================================================
      # EDGE CASE: Verify behavior when machine info available
      # ========================================================================
      # Even if we have machine info with IP address, we MUST NOT use it
      # The SSH proxy architecture means VM IP is irrelevant for SSH
      # ========================================================================

      context 'when machine info available with IP address (should be ignored)' do
        let(:machine_info) do
          {
            'record' => {
              'state' => 'running',
              'config' => {
                'default_username' => 'orbstack'
              }
            },
            'ip4' => '192.168.139.89'
          }
        end

        before do
          allow(VagrantPlugins::OrbStack::Util::OrbStackCLI)
            .to receive(:machine_info)
            .with('test-machine-id')
            .and_return(machine_info)
        end

        it 'still returns localhost:32222, ignoring VM IP address' do
          # Act
          result = provider.ssh_info

          # Assert
          expect(result[:host]).to eq('127.0.0.1'),
                                   'Must use SSH proxy at localhost even when VM IP is available'
          expect(result[:port]).to eq(32_222),
                                   'Must use SSH proxy port even when VM has port 22 available'
          expect(result[:username]).to eq('test-machine-id'),
                                       'Must use machine ID for proxy routing, not default_username'
        end
      end
    end

    # ========================================================================
    # EDGE CASE: Machine info not needed for SSH proxy
    # ========================================================================
    # With SSH proxy architecture, we don't need machine info or IP address
    # SSH connection uses localhost:32222 with machine ID for routing
    # ========================================================================

    context 'when machine is running (no machine info needed)' do
      let(:running_state) do
        Vagrant::MachineState.new(
          :running,
          'running',
          'Machine is running in OrbStack'
        )
      end

      before do
        allow(provider).to receive(:state).and_return(running_state)
      end

      it 'returns SSH info without needing to query machine info' do
        # Arrange - Don't mock machine_info call; it shouldn't be needed

        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_a(Hash)
        expect(result[:host]).to eq('127.0.0.1')
        expect(result[:port]).to eq(32_222)
        expect(result[:username]).to eq('test-machine-id')
        expect(result[:private_key_path]).to eq(File.expand_path('~/.orbstack/ssh/id_ed25519'))
      end
    end
  end
end
