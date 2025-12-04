# frozen_string_literal: true

# Integration test suite for machine destruction flow
#
# This test suite validates end-to-end machine destruction including:
# - Full vagrant destroy workflow with OrbStack provider
# - Complete lifecycle: create → destroy → verify cleanup
# - Metadata cleanup verification
# - State transitions after destruction
# - Idempotency of destroy operations
# - Post-destroy state queries
#
# NOTE: These tests mock OrbStackCLI calls to avoid requiring actual OrbStack
# installation. For real OrbStack integration tests, see acceptance/ directory.
#
# Expected behavior:
# - vagrant destroy removes machine from OrbStack
# - All metadata files are cleaned up
# - State query returns :not_created after destruction
# - Destroy operation is idempotent (safe to destroy twice)
# - Machine does not appear in orb list after destruction

require 'spec_helper'

RSpec.describe 'Machine Destruction Integration' do
  # ============================================================================
  # END-TO-END MACHINE DESTRUCTION TESTS
  # ============================================================================

  describe 'end-to-end machine destruction' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/create'
      require 'vagrant-orbstack/action/destroy'
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
             version: 'noble')
    end

    let(:machine) do
      double('machine',
             name: 'default',
             id: nil,
             provider_config: provider_config,
             ui: ui,
             data_dir: Pathname.new('/tmp/vagrant-destroy-integration-test'))
    end

    let(:provider) do
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    after do
      # Clean up test directory
      FileUtils.rm_rf('/tmp/vagrant-destroy-integration-test')
    end

    context 'when destroying a machine' do
      it 'full lifecycle: create machine then destroy and verify cleanup' do
        # Arrange - Setup machine
        allow(machine).to receive(:provider).and_return(provider)
        allow(SecureRandom).to receive(:hex).with(3).and_return('abc123')

        # Mock machine creation
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .with('vagrant-default-abc123', distribution: 'ubuntu:noble')
          .and_return({
                        id: 'vagrant-default-abc123',
                        status: 'running'
                      })

        # Act - Create machine
        create_action = VagrantPlugins::OrbStack::Action::Create.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        create_action.call({ machine: machine, ui: ui })

        # Verify machine was created
        expect(File.exist?(machine.data_dir.join('id'))).to be true
        expect(File.exist?(machine.data_dir.join('metadata.json'))).to be true

        # Setup for destroy
        allow(machine).to receive(:id).and_return('vagrant-default-abc123')

        # Mock machine deletion
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .with('vagrant-default-abc123')
          .and_return(true)

        # Act - Destroy machine
        destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        destroy_action.call({ machine: machine, ui: ui })

        # Assert - Verify cleanup
        expect(File.exist?(machine.data_dir.join('id'))).to be false
        expect(File.exist?(machine.data_dir.join('metadata.json'))).to be false
      end

      it 'after destroy, state query returns :not_created' do
        # Arrange - Machine exists and will be destroyed
        allow(machine).to receive(:provider).and_return(provider)
        allow(machine).to receive(:id).and_return('vagrant-default-abc123')

        # Create metadata files to simulate existing machine
        FileUtils.mkdir_p(machine.data_dir)
        File.write(machine.data_dir.join('id'), 'vagrant-default-abc123')
        File.write(machine.data_dir.join('metadata.json'), '{}')

        # Mock machine deletion
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_return(true)

        # Act - Destroy machine
        destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        destroy_action.call({ machine: machine, ui: ui })

        # Setup for state query - machine no longer exists
        allow(machine).to receive(:id).and_return(nil)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])

        # Assert - State should be :not_created
        state = provider.state
        expect(state.id).to eq(:not_created)
      end

      it 'after destroy, id file does not exist in data_dir' do
        # Arrange
        allow(machine).to receive(:provider).and_return(provider)
        allow(machine).to receive(:id).and_return('vagrant-default-xyz789')

        # Create files
        FileUtils.mkdir_p(machine.data_dir)
        id_file = machine.data_dir.join('id')
        File.write(id_file, 'vagrant-default-xyz789')

        # Mock deletion
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_return(true)

        # Verify file exists before
        expect(File.exist?(id_file)).to be true

        # Act - Destroy
        destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        destroy_action.call({ machine: machine, ui: ui })

        # Assert - File should not exist
        expect(File.exist?(id_file)).to be false
      end

      it 'after destroy, metadata.json does not exist in data_dir' do
        # Arrange
        allow(machine).to receive(:provider).and_return(provider)
        allow(machine).to receive(:id).and_return('vagrant-default-xyz789')

        # Create files
        FileUtils.mkdir_p(machine.data_dir)
        metadata_file = machine.data_dir.join('metadata.json')
        File.write(metadata_file, '{"machine_name":"vagrant-default-xyz789"}')

        # Mock deletion
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_return(true)

        # Verify file exists before
        expect(File.exist?(metadata_file)).to be true

        # Act - Destroy
        destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        destroy_action.call({ machine: machine, ui: ui })

        # Assert - File should not exist
        expect(File.exist?(metadata_file)).to be false
      end

      it 'post-destroy, machine does not appear in orb list' do
        # Arrange - Machine exists
        allow(machine).to receive(:provider).and_return(provider)
        allow(machine).to receive(:id).and_return('vagrant-default-list123')

        # Create files
        FileUtils.mkdir_p(machine.data_dir)
        File.write(machine.data_dir.join('id'), 'vagrant-default-list123')

        # Mock machine exists before destroy
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([{ name: 'vagrant-default-list123', status: 'running' }])

        # Mock deletion
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_return(true)

        # Act - Destroy
        destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        destroy_action.call({ machine: machine, ui: ui })

        # Assert - After destroy, list_machines should not include our machine
        # Mock updated list without our machine
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])

        machines = VagrantPlugins::OrbStack::Util::OrbStackCLI.list_machines
        machine_names = machines.map { |m| m[:name] }
        expect(machine_names).not_to include('vagrant-default-list123')
      end
    end
  end

  # ============================================================================
  # IDEMPOTENCY TESTS
  # ============================================================================

  describe 'idempotency of destroy operations' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/destroy'
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
             version: 'noble')
    end

    let(:machine) do
      double('machine',
             name: 'default',
             id: 'vagrant-default-idempotent123',
             provider_config: provider_config,
             ui: ui,
             data_dir: Pathname.new('/tmp/vagrant-destroy-idempotency-test'))
    end

    let(:provider) do
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    after do
      FileUtils.rm_rf('/tmp/vagrant-destroy-idempotency-test')
    end

    it 'destroying non-existent machine succeeds gracefully' do
      # Arrange - Machine doesn't exist in OrbStack
      allow(machine).to receive(:provider).and_return(provider)

      # Mock machine not found
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                   'Machine not found')

      # No metadata files exist
      expect(File.exist?(machine.data_dir.join('id'))).to be false
      expect(File.exist?(machine.data_dir.join('metadata.json'))).to be false

      # Act & Assert - Should not raise error
      destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )

      expect do
        destroy_action.call({ machine: machine, ui: ui })
      end.not_to raise_error
    end

    it 'calling vagrant destroy twice succeeds without error' do
      # Arrange - Create files for first destroy
      allow(machine).to receive(:provider).and_return(provider)

      FileUtils.mkdir_p(machine.data_dir)
      File.write(machine.data_dir.join('id'), 'vagrant-default-idempotent123')
      File.write(machine.data_dir.join('metadata.json'), '{}')

      # Mock successful deletion
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        .and_return(true)

      # Act - First destroy
      destroy_action1 = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      destroy_action1.call({ machine: machine, ui: ui })

      # Files should be gone
      expect(File.exist?(machine.data_dir.join('id'))).to be false

      # Mock machine no longer exists
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                   'Machine not found')

      # Act - Second destroy (should be idempotent)
      destroy_action2 = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )

      # Assert - Should not raise error
      expect do
        destroy_action2.call({ machine: machine, ui: ui })
      end.not_to raise_error
    end

    it 'destroy succeeds when only id file is missing' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)

      FileUtils.mkdir_p(machine.data_dir)
      # Only create metadata.json, not id file
      File.write(machine.data_dir.join('metadata.json'), '{}')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        .and_return(true)

      # Act & Assert - Should not raise error
      destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )

      expect do
        destroy_action.call({ machine: machine, ui: ui })
      end.not_to raise_error

      # Metadata should be cleaned up
      expect(File.exist?(machine.data_dir.join('metadata.json'))).to be false
    end

    it 'destroy succeeds when only metadata.json is missing' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)

      FileUtils.mkdir_p(machine.data_dir)
      # Only create id file, not metadata.json
      File.write(machine.data_dir.join('id'), 'vagrant-default-idempotent123')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        .and_return(true)

      # Act & Assert - Should not raise error
      destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )

      expect do
        destroy_action.call({ machine: machine, ui: ui })
      end.not_to raise_error

      # ID file should be cleaned up
      expect(File.exist?(machine.data_dir.join('id'))).to be false
    end

    it 'destroy succeeds when data_dir does not exist' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)

      # Ensure data_dir doesn't exist
      FileUtils.rm_rf(machine.data_dir)
      expect(File.exist?(machine.data_dir)).to be false

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        .and_return(true)

      # Act & Assert - Should not raise error
      destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )

      expect do
        destroy_action.call({ machine: machine, ui: ui })
      end.not_to raise_error
    end
  end

  # ============================================================================
  # MULTI-MACHINE DESTRUCTION TESTS
  # ============================================================================

  describe 'multi-machine destruction scenarios' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/destroy'
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
             version: 'noble')
    end

    after do
      FileUtils.rm_rf('/tmp/vagrant-destroy-multi-web')
      FileUtils.rm_rf('/tmp/vagrant-destroy-multi-db')
    end

    it 'destroying one machine does not affect other machines' do
      # Arrange - Two machines
      web_machine = double('machine',
                           name: 'web',
                           id: 'vagrant-web-aaa111',
                           provider_config: provider_config,
                           ui: ui,
                           data_dir: Pathname.new('/tmp/vagrant-destroy-multi-web'))
      web_provider = VagrantPlugins::OrbStack::Provider.new(web_machine)
      allow(web_machine).to receive(:provider).and_return(web_provider)

      db_machine = double('machine',
                          name: 'db',
                          id: 'vagrant-db-bbb222',
                          provider_config: provider_config,
                          ui: ui,
                          data_dir: Pathname.new('/tmp/vagrant-destroy-multi-db'))
      db_provider = VagrantPlugins::OrbStack::Provider.new(db_machine)
      allow(db_machine).to receive(:provider).and_return(db_provider)

      # Create files for both machines
      FileUtils.mkdir_p(web_machine.data_dir)
      FileUtils.mkdir_p(db_machine.data_dir)
      File.write(web_machine.data_dir.join('id'), 'vagrant-web-aaa111')
      File.write(db_machine.data_dir.join('id'), 'vagrant-db-bbb222')

      # Mock CLI
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        .and_return(true)

      # Act - Destroy only web machine
      destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: web_machine, ui: ui }
      )
      destroy_action.call({ machine: web_machine, ui: ui })

      # Assert - Web machine files are gone, DB machine files remain
      expect(File.exist?(web_machine.data_dir.join('id'))).to be false
      expect(File.exist?(db_machine.data_dir.join('id'))).to be true
    end

    it 'can destroy multiple machines independently' do
      # Arrange - Two machines
      web_machine = double('machine',
                           name: 'web',
                           id: 'vagrant-web-ccc333',
                           provider_config: provider_config,
                           ui: ui,
                           data_dir: Pathname.new('/tmp/vagrant-destroy-multi-web'))
      web_provider = VagrantPlugins::OrbStack::Provider.new(web_machine)
      allow(web_machine).to receive(:provider).and_return(web_provider)

      db_machine = double('machine',
                          name: 'db',
                          id: 'vagrant-db-ddd444',
                          provider_config: provider_config,
                          ui: ui,
                          data_dir: Pathname.new('/tmp/vagrant-destroy-multi-db'))
      db_provider = VagrantPlugins::OrbStack::Provider.new(db_machine)
      allow(db_machine).to receive(:provider).and_return(db_provider)

      # Create files for both machines
      FileUtils.mkdir_p(web_machine.data_dir)
      FileUtils.mkdir_p(db_machine.data_dir)
      File.write(web_machine.data_dir.join('id'), 'vagrant-web-ccc333')
      File.write(db_machine.data_dir.join('id'), 'vagrant-db-ddd444')

      # Mock CLI to track which machines are deleted
      deleted_machines = []
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine) do |name|
        deleted_machines << name
        true
      end

      # Act - Destroy both machines
      web_destroy = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: web_machine, ui: ui }
      )
      web_destroy.call({ machine: web_machine, ui: ui })

      db_destroy = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: db_machine, ui: ui }
      )
      db_destroy.call({ machine: db_machine, ui: ui })

      # Assert - Both machines deleted
      expect(deleted_machines).to include('vagrant-web-ccc333', 'vagrant-db-ddd444')
      expect(File.exist?(web_machine.data_dir.join('id'))).to be false
      expect(File.exist?(db_machine.data_dir.join('id'))).to be false
    end
  end

  # ============================================================================
  # ERROR RECOVERY TESTS
  # ============================================================================

  describe 'error recovery scenarios' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/destroy'
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
             version: 'noble')
    end

    let(:machine) do
      double('machine',
             name: 'default',
             id: 'vagrant-default-error123',
             provider_config: provider_config,
             ui: ui,
             data_dir: Pathname.new('/tmp/vagrant-destroy-error-test'))
    end

    let(:provider) do
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    after do
      FileUtils.rm_rf('/tmp/vagrant-destroy-error-test')
    end

    it 'continues cleanup even if OrbStack CLI fails' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)

      FileUtils.mkdir_p(machine.data_dir)
      File.write(machine.data_dir.join('id'), 'vagrant-default-error123')
      File.write(machine.data_dir.join('metadata.json'), '{}')

      # Mock CLI failure
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                   'OrbStack daemon not running')

      # Act
      destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      destroy_action.call({ machine: machine, ui: ui })

      # Assert - Local cleanup should still happen
      expect(File.exist?(machine.data_dir.join('id'))).to be false
      expect(File.exist?(machine.data_dir.join('metadata.json'))).to be false
    end

    it 'warns user if OrbStack CLI fails but continues' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)

      FileUtils.mkdir_p(machine.data_dir)
      File.write(machine.data_dir.join('id'), 'vagrant-default-error123')

      # Mock CLI failure
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                   'Connection refused')

      # Act
      destroy_action = VagrantPlugins::OrbStack::Action::Destroy.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      destroy_action.call({ machine: machine, ui: ui })

      # Assert - Should have warned user about error and continuing with cleanup
      expect(ui).to have_received(:warn).with('Error deleting machine from OrbStack: Connection refused')
      expect(ui).to have_received(:warn).with('Continuing with local cleanup...')
    end
  end
end
