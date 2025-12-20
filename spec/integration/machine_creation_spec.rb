# frozen_string_literal: true

# Integration test suite for machine creation flow
#
# This test suite validates end-to-end machine creation including:
# - Full vagrant up workflow with OrbStack provider
# - Machine naming and uniqueness
# - Idempotency of creation operations
# - Multi-machine scenarios
# - Error handling and recovery
#
# NOTE: These tests mock OrbStackCLI calls to avoid requiring actual OrbStack
# installation. For real OrbStack integration tests, see acceptance/ directory.
#
# Expected behavior:
# - vagrant up creates machine with correct naming convention
# - Repeated vagrant up is idempotent (no duplicate machines)
# - Multi-machine Vagrantfiles create unique machines
# - Metadata persists correctly across operations
# - Errors are handled gracefully with clear messages

require 'spec_helper'

RSpec.describe 'Machine Creation Integration' do
  # ============================================================================
  # END-TO-END MACHINE CREATION TESTS
  # ============================================================================

  describe 'end-to-end machine creation' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/create'
      require 'vagrant-orbstack/util/machine_namer'
      require 'vagrant-orbstack/util/ssh_readiness_checker'

      # Stub SSH readiness checker since we mock OrbStackCLI (no real machines)
      allow(VagrantPlugins::OrbStack::Util::SSHReadinessChecker)
        .to receive(:wait_for_ready).and_return(true)
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
             data_dir: Pathname.new('/tmp/vagrant-integration-test'))
    end

    let(:provider) do
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    after do
      # Clean up test directory
      FileUtils.rm_rf('/tmp/vagrant-integration-test')
    end

    context 'when creating machine with default configuration' do
      it 'creates machine with vagrant-<name>-<id> naming convention' do
        # Arrange
        allow(machine).to receive(:provider).and_return(provider)
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Mock OrbStack CLI
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .with('vagrant-default-a3b2c1', distribution: 'ubuntu:noble')
          .and_return({
                        id: 'vagrant-default-a3b2c1',
                        name: 'vagrant-default-a3b2c1',
                        status: 'running',
                        distro: 'ubuntu:noble'
                      })

        # Act
        action = VagrantPlugins::OrbStack::Action::Create.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        env = { machine: machine, ui: ui }
        action.call(env)

        # Assert - verify machine ID was written
        expect(File.exist?(machine.data_dir.join('id'))).to be true
        expect(File.read(machine.data_dir.join('id')).strip).to eq('vagrant-default-a3b2c1')
      end

      it 'machine is in running state after creation' do
        # Arrange
        allow(machine).to receive(:provider).and_return(provider)
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Mock OrbStack CLI
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_return({
                        id: 'vagrant-default-a3b2c1',
                        name: 'vagrant-default-a3b2c1',
                        status: 'running'
                      })

        # Act - simulate machine creation
        allow(machine).to receive(:id).and_return('vagrant-default-a3b2c1')

        # Mock list_machines to return our created machine
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([{
                        name: 'vagrant-default-a3b2c1',
                        status: 'running'
                      }])

        # Assert
        state = provider.state
        expect(state.id).to eq(:running)
      end

      it 'machine metadata is persisted correctly' do
        # Arrange
        allow(machine).to receive(:provider).and_return(provider)
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_return({
                        id: 'vagrant-default-a3b2c1',
                        status: 'running'
                      })

        # Act
        action = VagrantPlugins::OrbStack::Action::Create.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        action.call({ machine: machine, ui: ui })

        # Assert - verify metadata was written
        expect(File.exist?(machine.data_dir.join('metadata.json'))).to be true
        metadata = JSON.parse(File.read(machine.data_dir.join('metadata.json')))
        expect(metadata['machine_name']).to eq('vagrant-default-a3b2c1')
        expect(metadata['distribution']).to eq('ubuntu:noble')
        expect(metadata).to have_key('created_at')
      end
    end

    context 'when creating machine with custom distribution' do
      it 'creates machine with specified Ubuntu Jammy distribution' do
        # Arrange
        custom_config = double('provider_config',
                               distro: 'ubuntu',
                               version: 'jammy')
        custom_machine = double('machine',
                                name: 'web',
                                id: nil,
                                provider_config: custom_config,
                                ui: ui,
                                data_dir: Pathname.new('/tmp/vagrant-integration-test-custom'))
        # Create provider with custom_machine so @machine.data_dir matches
        custom_provider = VagrantPlugins::OrbStack::Provider.new(custom_machine)
        allow(custom_machine).to receive(:provider).and_return(custom_provider)
        allow(SecureRandom).to receive(:hex).with(3).and_return('b4c5d6')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .with('vagrant-web-b4c5d6', distribution: 'ubuntu:jammy')
          .and_return({
                        id: 'vagrant-web-b4c5d6',
                        status: 'running'
                      })

        # Act
        action = VagrantPlugins::OrbStack::Action::Create.new(
          ->(env) { env },
          { machine: custom_machine, ui: ui }
        )
        action.call({ machine: custom_machine, ui: ui })

        # Assert - verify metadata includes correct distro
        metadata = JSON.parse(File.read(custom_machine.data_dir.join('metadata.json')))
        expect(metadata['distribution']).to eq('ubuntu:jammy')
      ensure
        FileUtils.rm_rf('/tmp/vagrant-integration-test-custom')
      end
    end

    context 'when creating machine with custom machine name' do
      it 'uses custom name in generated machine identifier' do
        # Arrange
        named_machine = double('machine',
                               name: 'database',
                               id: nil,
                               provider_config: provider_config,
                               ui: ui,
                               data_dir: Pathname.new('/tmp/vagrant-integration-test-named'))
        # Create provider with named_machine so @machine.data_dir matches
        named_provider = VagrantPlugins::OrbStack::Provider.new(named_machine)
        allow(named_machine).to receive(:provider).and_return(named_provider)
        allow(SecureRandom).to receive(:hex).with(3).and_return('c6d7e8')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .with('vagrant-database-c6d7e8', anything)
          .and_return({
                        id: 'vagrant-database-c6d7e8',
                        status: 'running'
                      })

        # Act
        action = VagrantPlugins::OrbStack::Action::Create.new(
          ->(env) { env },
          { machine: named_machine, ui: ui }
        )
        action.call({ machine: named_machine, ui: ui })

        # Assert
        expect(File.read(named_machine.data_dir.join('id')).strip).to eq('vagrant-database-c6d7e8')
      ensure
        FileUtils.rm_rf('/tmp/vagrant-integration-test-named')
      end
    end
  end

  # ============================================================================
  # IDEMPOTENCY TESTS
  # ============================================================================

  describe 'idempotency of creation operations' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/create'
      require 'vagrant-orbstack/util/ssh_readiness_checker'

      # Stub SSH readiness checker since we mock OrbStackCLI (no real machines)
      allow(VagrantPlugins::OrbStack::Util::SSHReadinessChecker)
        .to receive(:wait_for_ready).and_return(true)
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
             id: nil,
             provider_config: provider_config,
             ui: ui,
             data_dir: Pathname.new('/tmp/vagrant-idempotency-test'))
    end

    let(:provider) do
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    after do
      FileUtils.rm_rf('/tmp/vagrant-idempotency-test')
    end

    it 'calling vagrant up twice on running machine succeeds without creating duplicate' do
      # Arrange - first creation
      allow(machine).to receive(:provider).and_return(provider)
      allow(machine).to receive(:id).and_return(nil, 'vagrant-default-a3b2c1')
      allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([])
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
        .and_return({ id: 'vagrant-default-a3b2c1', status: 'running' })

      # First vagrant up
      action1 = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      action1.call({ machine: machine, ui: ui })

      # Setup for second call - machine now has ID and is running
      allow(machine).to receive(:id).and_return('vagrant-default-a3b2c1')
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([{ name: 'vagrant-default-a3b2c1', status: 'running' }])

      # Act - second vagrant up (should be no-op)
      action2 = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )

      # Assert - should NOT call create_machine again
      expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).not_to receive(:create_machine)
      action2.call({ machine: machine, ui: ui })
    end

    it 'calling vagrant up on stopped machine starts it without recreating' do
      # Arrange - machine exists but is stopped
      allow(machine).to receive(:provider).and_return(provider)
      allow(machine).to receive(:id).and_return('vagrant-default-a3b2c1')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([{ name: 'vagrant-default-a3b2c1', status: 'stopped' }])

      # Should call start_machine, not create_machine
      expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
        .with('vagrant-default-a3b2c1')
        .and_return({ id: 'vagrant-default-a3b2c1', status: 'running' })

      expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).not_to receive(:create_machine)

      # Act
      action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      action.call({ machine: machine, ui: ui })
    end

    it 'machine ID remains consistent across multiple vagrant up calls' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)
      allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

      # First creation
      allow(machine).to receive(:id).and_return(nil, 'vagrant-default-a3b2c1')
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([])
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
        .and_return({ id: 'vagrant-default-a3b2c1', status: 'running' })

      action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      action.call({ machine: machine, ui: ui })

      # Act - read ID from metadata
      stored_id = File.read(machine.data_dir.join('id')).strip

      # Assert
      expect(stored_id).to eq('vagrant-default-a3b2c1')

      # Second vagrant up should use same ID
      allow(machine).to receive(:id).and_return('vagrant-default-a3b2c1')
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([{ name: 'vagrant-default-a3b2c1', status: 'running' }])

      action2 = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )
      action2.call({ machine: machine, ui: ui })

      # ID should remain the same
      expect(File.read(machine.data_dir.join('id')).strip).to eq('vagrant-default-a3b2c1')
    end
  end

  # ============================================================================
  # MULTI-MACHINE SCENARIO TESTS
  # ============================================================================

  describe 'multi-machine scenarios' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/create'
      require 'vagrant-orbstack/util/machine_namer'
      require 'vagrant-orbstack/util/ssh_readiness_checker'

      # Stub SSH readiness checker since we mock OrbStackCLI (no real machines)
      allow(VagrantPlugins::OrbStack::Util::SSHReadinessChecker)
        .to receive(:wait_for_ready).and_return(true)
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
      FileUtils.rm_rf('/tmp/vagrant-multi-test-web')
      FileUtils.rm_rf('/tmp/vagrant-multi-test-db')
      FileUtils.rm_rf('/tmp/vagrant-multi-test-cache')
    end

    it 'creates multiple machines with different names (no collision)' do
      # Arrange - web machine
      web_machine = double('machine',
                           name: 'web',
                           id: nil,
                           provider_config: provider_config,
                           ui: ui,
                           data_dir: Pathname.new('/tmp/vagrant-multi-test-web'))
      web_provider = VagrantPlugins::OrbStack::Provider.new(web_machine)
      allow(web_machine).to receive(:provider).and_return(web_provider)

      # Arrange - db machine
      db_machine = double('machine',
                          name: 'db',
                          id: nil,
                          provider_config: provider_config,
                          ui: ui,
                          data_dir: Pathname.new('/tmp/vagrant-multi-test-db'))
      db_provider = VagrantPlugins::OrbStack::Provider.new(db_machine)
      allow(db_machine).to receive(:provider).and_return(db_provider)

      # Mock different IDs for each machine
      allow(SecureRandom).to receive(:hex).with(3).and_return('a1b2c3', 'd4e5f6')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([])
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
        .and_return({ status: 'running' })

      # Act - create both machines
      web_action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: web_machine, ui: ui }
      )
      web_action.call({ machine: web_machine, ui: ui })

      db_action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: db_machine, ui: ui }
      )
      db_action.call({ machine: db_machine, ui: ui })

      # Assert - both machines have unique IDs
      web_id = File.read(web_machine.data_dir.join('id')).strip
      db_id = File.read(db_machine.data_dir.join('id')).strip

      expect(web_id).to eq('vagrant-web-a1b2c3')
      expect(db_id).to eq('vagrant-db-d4e5f6')
      expect(web_id).not_to eq(db_id)
    end

    it 'generates unique names for each machine in Vagrantfile' do
      # Arrange - simulate 3-machine Vagrantfile
      machines = %w[web db cache].map.with_index do |name, _index|
        m = double('machine',
                   name: name,
                   id: nil,
                   provider_config: provider_config,
                   ui: ui,
                   data_dir: Pathname.new("/tmp/vagrant-multi-test-#{name}"))
        p = VagrantPlugins::OrbStack::Provider.new(m)
        allow(m).to receive(:provider).and_return(p)
        m
      end

      # Mock unique IDs
      allow(SecureRandom).to receive(:hex).with(3)
                                          .and_return('111111', '222222', '333333')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([])
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
        .and_return({ status: 'running' })

      # Act - create all machines
      created_ids = machines.map do |machine|
        action = VagrantPlugins::OrbStack::Action::Create.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        action.call({ machine: machine, ui: ui })
        File.read(machine.data_dir.join('id')).strip
      end

      # Assert - all IDs are unique
      expect(created_ids.uniq.length).to eq(3)
      expect(created_ids).to include('vagrant-web-111111')
      expect(created_ids).to include('vagrant-db-222222')
      expect(created_ids).to include('vagrant-cache-333333')
    end

    it 'handles Vagrantfile with multiple machine definitions' do
      # This test verifies the naming collision avoidance works
      # when machines already exist in OrbStack

      # Arrange - first machine already exists
      existing_machines = [
        { name: 'vagrant-web-a1b2c3', status: 'running' }
      ]

      web_machine = double('machine',
                           name: 'web',
                           id: nil,
                           provider_config: provider_config,
                           ui: ui,
                           data_dir: Pathname.new('/tmp/vagrant-multi-test-web'))
      web_provider = VagrantPlugins::OrbStack::Provider.new(web_machine)
      allow(web_machine).to receive(:provider).and_return(web_provider)

      # Mock collision on first attempt, success on second
      allow(SecureRandom).to receive(:hex).with(3).and_return('a1b2c3', 'd4e5f6')

      call_count = 0
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines) do
        call_count += 1
        call_count == 1 ? existing_machines : []
      end

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
        .and_return({ status: 'running' })

      # Act
      action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: web_machine, ui: ui }
      )
      action.call({ machine: web_machine, ui: ui })

      # Assert - should have used second ID due to collision
      created_id = File.read(web_machine.data_dir.join('id')).strip
      expect(created_id).to eq('vagrant-web-d4e5f6')
    end

    it 'each machine has unique metadata' do
      # Arrange - two machines
      web_machine = double('machine',
                           name: 'web',
                           id: nil,
                           provider_config: provider_config,
                           ui: ui,
                           data_dir: Pathname.new('/tmp/vagrant-multi-test-web'))
      web_provider = VagrantPlugins::OrbStack::Provider.new(web_machine)
      allow(web_machine).to receive(:provider).and_return(web_provider)

      db_machine = double('machine',
                          name: 'db',
                          id: nil,
                          provider_config: provider_config,
                          ui: ui,
                          data_dir: Pathname.new('/tmp/vagrant-multi-test-db'))
      db_provider = VagrantPlugins::OrbStack::Provider.new(db_machine)
      allow(db_machine).to receive(:provider).and_return(db_provider)

      allow(SecureRandom).to receive(:hex).with(3).and_return('aaa111', 'bbb222')
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([])
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
        .and_return({ status: 'running' })

      # Act
      [web_machine, db_machine].each do |machine|
        action = VagrantPlugins::OrbStack::Action::Create.new(
          ->(env) { env },
          { machine: machine, ui: ui }
        )
        action.call({ machine: machine, ui: ui })
      end

      # Assert
      web_metadata = JSON.parse(File.read(web_machine.data_dir.join('metadata.json')))
      db_metadata = JSON.parse(File.read(db_machine.data_dir.join('metadata.json')))

      expect(web_metadata['machine_name']).to eq('vagrant-web-aaa111')
      expect(db_metadata['machine_name']).to eq('vagrant-db-bbb222')
      expect(web_metadata['machine_name']).not_to eq(db_metadata['machine_name'])
    end
  end

  # ============================================================================
  # ERROR SCENARIO TESTS
  # ============================================================================

  describe 'error scenarios' do
    before do
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/create'
      require 'vagrant-orbstack/util/ssh_readiness_checker'

      # Stub SSH readiness checker since we mock OrbStackCLI (no real machines)
      allow(VagrantPlugins::OrbStack::Util::SSHReadinessChecker)
        .to receive(:wait_for_ready).and_return(true)
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
             id: nil,
             provider_config: provider_config,
             ui: ui,
             data_dir: Pathname.new('/tmp/vagrant-error-test'))
    end

    let(:provider) do
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    after do
      FileUtils.rm_rf('/tmp/vagrant-error-test')
    end

    it 'fails gracefully if OrbStack is not installed' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackNotInstalledError,
                   'OrbStack is not installed')

      # Act & Assert
      action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )

      expect do
        action.call({ machine: machine, ui: ui })
      end.to raise_error(VagrantPlugins::OrbStack::Errors::OrbStackNotInstalledError)
    end

    it 'fails gracefully if invalid distribution specified' do
      # Arrange
      invalid_config = double('provider_config',
                              distro: 'invalid-distro',
                              version: 'nonexistent')
      invalid_machine = double('machine',
                               name: 'default',
                               id: nil,
                               provider_config: invalid_config,
                               ui: ui,
                               data_dir: Pathname.new('/tmp/vagrant-error-test'))
      allow(invalid_machine).to receive(:provider).and_return(provider)

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([])
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
        .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackCLIError,
                   'Invalid distribution: invalid-distro:nonexistent')

      # Act & Assert
      action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: invalid_machine, ui: ui }
      )

      expect do
        action.call({ machine: invalid_machine, ui: ui })
      end.to raise_error(VagrantPlugins::OrbStack::Errors::OrbStackCLIError, /Invalid distribution/)
    end

    it 'provides clear error message on creation failure' do
      # Arrange
      allow(machine).to receive(:provider).and_return(provider)
      allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
        .and_return([])
      allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
        .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackCLIError,
                   'Failed to create machine: disk full')

      # Act & Assert
      action = VagrantPlugins::OrbStack::Action::Create.new(
        ->(env) { env },
        { machine: machine, ui: ui }
      )

      expect do
        action.call({ machine: machine, ui: ui })
      end.to raise_error(
        VagrantPlugins::OrbStack::Errors::OrbStackCLIError,
        /disk full/
      )
    end
  end
end
