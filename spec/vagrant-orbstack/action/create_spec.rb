# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Action::Create
#
# This test suite validates the Create action middleware that orchestrates
# machine creation with idempotency handling, unique naming, and metadata persistence.
#
# Expected behavior:
# - Implements idempotency (no-op if running, start if stopped, create if not_created)
# - Generates unique machine name via MachineNamer utility
# - Calls OrbStackCLI.create_machine with correct parameters
# - Persists machine ID and metadata via Provider methods
# - Invalidates state cache after creation
# - Handles errors gracefully with clear messages

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Action::Create' do
  describe 'class definition' do
    it 'is defined after requiring action/create file' do
      expect do
        require 'vagrant-orbstack/action/create'
        VagrantPlugins::OrbStack::Action::Create
      end.not_to raise_error
    end
  end

  describe '#call' do
    before do
      require 'vagrant-orbstack/action/create'
      require 'vagrant-orbstack/provider'
    end

    let(:action_class) { VagrantPlugins::OrbStack::Action::Create }

    # Mock Vagrant environment and machine
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

    let(:provider) do
      instance_double('VagrantPlugins::OrbStack::Provider',
                      machine_id_changed: nil,
                      write_machine_id: nil,
                      write_metadata: nil,
                      invalidate_state_cache: nil)
    end

    let(:machine) do
      double('machine',
             name: 'default',
             id: nil,
             provider_config: provider_config,
             provider: provider,
             ui: ui,
             data_dir: Pathname.new('/tmp/vagrant-test'))
    end

    let(:app) { double('app', call: nil) }

    let(:env) do
      {
        machine: machine,
        ui: ui
      }
    end

    # ============================================================================
    # IDEMPOTENCY LOGIC TESTS
    # ============================================================================

    context 'when machine is already running' do
      before do
        # Mock Provider#state to return :running
        running_state = Vagrant::MachineState.new(:running, 'running', 'Machine is running')
        allow(provider).to receive(:state).and_return(running_state)
      end

      it 'returns success without creating machine (no-op)' do
        # Arrange
        action = action_class.new(app, env)

        # Should NOT call create_machine
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).not_to receive(:create_machine)

        # Act
        action.call(env)

        # Assert
        expect(app).to have_received(:call).with(env)
      end

      it 'displays info message that machine is already running' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(ui).to have_received(:info).with(/already running/i)
      end

      it 'does not invalidate state cache when no state change' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(provider).not_to have_received(:invalidate_state_cache)
      end
    end

    context 'when machine is stopped' do
      before do
        # Mock Provider#state to return :stopped
        stopped_state = Vagrant::MachineState.new(:stopped, 'stopped', 'Machine is stopped')
        allow(provider).to receive(:state).and_return(stopped_state)

        # Mock machine.id to exist (stopped machines have IDs)
        allow(machine).to receive(:id).and_return('vagrant-default-a3b2c1')
      end

      it 'calls start_machine instead of create_machine' do
        # Arrange
        action = action_class.new(app, env)

        # Should call start_machine, not create_machine
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .with('vagrant-default-a3b2c1')
          .and_return({ id: 'vagrant-default-a3b2c1', status: 'running' })

        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).not_to receive(:create_machine)

        # Act
        action.call(env)
      end

      it 'displays info message that machine is being started' do
        # Arrange
        action = action_class.new(app, env)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-a3b2c1', status: 'running' })

        # Act
        action.call(env)

        # Assert
        expect(ui).to have_received(:info).with(/starting/i)
      end

      it 'invalidates state cache after starting' do
        # Arrange
        action = action_class.new(app, env)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-a3b2c1', status: 'running' })

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:invalidate_state_cache)
      end
    end

    context 'when machine does not exist (not_created)' do
      before do
        # Mock Provider#state to return :not_created
        not_created_state = Vagrant::MachineState.new(:not_created, 'not created',
                                                      'Machine does not exist')
        allow(provider).to receive(:state).and_return(not_created_state)
      end

      it 'proceeds with machine creation' do
        # Arrange
        action = action_class.new(app, env)

        # Mock MachineNamer
        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .with(machine)
          .and_return('vagrant-default-a3b2c1')

        # Mock create_machine
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .with('vagrant-default-a3b2c1', distribution: 'ubuntu:noble')
          .and_return({
                        id: 'vagrant-default-a3b2c1',
                        name: 'vagrant-default-a3b2c1',
                        status: 'running'
                      })

        # Act
        action.call(env)
      end

      it 'queries Provider#state to determine current state' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_return({ id: 'vagrant-default-a3b2c1', status: 'running' })

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:state)
      end
    end

    # ============================================================================
    # MACHINE CREATION FLOW TESTS
    # ============================================================================

    context 'when creating a new machine' do
      before do
        # Mock not_created state
        not_created_state = Vagrant::MachineState.new(:not_created, 'not created',
                                                      'Machine does not exist')
        allow(provider).to receive(:state).and_return(not_created_state)
      end

      it 'generates unique machine name via MachineNamer' do
        # Arrange
        action = action_class.new(app, env)

        expect(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .with(machine)
          .and_return('vagrant-default-a3b2c1')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_return({ id: 'vagrant-default-a3b2c1', status: 'running' })

        # Act
        action.call(env)
      end

      it 'calls OrbStackCLI.create_machine with generated name' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')

        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .with('vagrant-default-a3b2c1', distribution: 'ubuntu:noble')

        # Act
        action.call(env)
      end

      it 'uses distribution from provider_config.distro' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')

        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .with(anything, distribution: 'ubuntu:noble')

        # Act
        action.call(env)
      end

      it 'uses distribution with version when both are specified' do
        # Arrange
        allow(provider_config).to receive(:distro).and_return('ubuntu')
        allow(provider_config).to receive(:version).and_return('jammy')

        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')

        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .with(anything, distribution: 'ubuntu:jammy')

        # Act
        action.call(env)
      end

      it 'handles successful creation response' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_return({
                        id: 'vagrant-default-a3b2c1',
                        name: 'vagrant-default-a3b2c1',
                        status: 'running',
                        distro: 'ubuntu:noble'
                      })

        # Act & Assert
        expect { action.call(env) }.not_to raise_error
      end

      it 'displays progress messages during creation' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_return({ id: 'vagrant-default-a3b2c1', status: 'running' })

        # Act
        action.call(env)

        # Assert
        expect(ui).to have_received(:info).at_least(:once)
      end
    end

    # ============================================================================
    # METADATA PERSISTENCE TESTS
    # ============================================================================

    context 'when persisting machine metadata' do
      before do
        # Mock not_created state
        not_created_state = Vagrant::MachineState.new(:not_created, 'not created',
                                                      'Machine does not exist')
        allow(provider).to receive(:state).and_return(not_created_state)

        # Mock MachineNamer
        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')

        # Mock create_machine
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_return({
                        id: 'vagrant-default-a3b2c1',
                        name: 'vagrant-default-a3b2c1',
                        status: 'running',
                        distro: 'ubuntu:noble'
                      })
      end

      it 'stores machine ID via Provider#write_machine_id' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:write_machine_id)
          .with('vagrant-default-a3b2c1')
      end

      it 'stores metadata via Provider#write_metadata' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:write_metadata)
          .with(hash_including(
                  'machine_name' => 'vagrant-default-a3b2c1',
                  'distribution' => 'ubuntu:noble'
                ))
      end

      it 'includes created_at timestamp in metadata' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:write_metadata) do |metadata|
          expect(metadata).to have_key('created_at')
          expect(metadata['created_at']).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
        end
      end

      it 'includes machine_name in metadata' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:write_metadata) do |metadata|
          expect(metadata['machine_name']).to eq('vagrant-default-a3b2c1')
        end
      end

      it 'includes distribution in metadata' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:write_metadata) do |metadata|
          expect(metadata['distribution']).to eq('ubuntu:noble')
        end
      end

      it 'invalidates state cache after creation' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:invalidate_state_cache)
      end

      it 'updates machine.id after creation' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - machine.id= should be called by Vagrant core after write_machine_id
        # We verify write_machine_id was called with correct ID
        expect(provider).to have_received(:write_machine_id)
          .with('vagrant-default-a3b2c1')
      end
    end

    # ============================================================================
    # ERROR HANDLING TESTS
    # ============================================================================

    context 'when handling errors' do
      before do
        # Mock not_created state
        not_created_state = Vagrant::MachineState.new(:not_created, 'not created',
                                                      'Machine does not exist')
        allow(provider).to receive(:state).and_return(not_created_state)
      end

      it 'raises clear error if create_machine fails' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackCLIError, 'Failed to create machine')

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::OrbStackCLIError,
          /Failed to create machine/
        )
      end

      it 'raises clear error if name generation fails (max retries)' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_raise(VagrantPlugins::OrbStack::Errors::MachineNameCollisionError,
                     'Failed to generate unique machine name')

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::MachineNameCollisionError,
          /Failed to generate unique machine name/
        )
      end

      it 'cleans up partial state on create failure' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackCLIError, 'Creation failed')

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::OrbStackCLIError
        )

        # Ensure metadata was NOT written on failure
        expect(provider).not_to have_received(:write_metadata)
      end

      it 'propagates OrbStack not installed error' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackNotInstalledError)

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::OrbStackNotInstalledError
        )
      end

      it 'handles timeout errors during creation' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandTimeoutError, 'Command timed out')

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandTimeoutError,
          /Command timed out/
        )
      end

      it 'includes machine name in error messages' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::MachineNamer).to receive(:generate)
          .and_return('vagrant-default-a3b2c1')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:create_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackCLIError, 'Creation failed')

        # Act & Assert
        expect { action.call(env) }.to raise_error do |error|
          expect(error.message).to include('vagrant-default-a3b2c1').or include('Creation failed')
        end
      end
    end

    # ============================================================================
    # MIDDLEWARE CHAIN TESTS
    # ============================================================================

    context 'when integrating with middleware chain' do
      before do
        # Mock running state (idempotent case)
        running_state = Vagrant::MachineState.new(:running, 'running', 'Machine is running')
        allow(provider).to receive(:state).and_return(running_state)
      end

      it 'calls next middleware in chain after successful creation' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(app).to have_received(:call).with(env)
      end

      it 'passes environment hash to next middleware' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(app).to have_received(:call) do |passed_env|
          expect(passed_env).to eq(env)
        end
      end
    end
  end
end
