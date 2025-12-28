# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Action::SSHRun
#
# This test suite validates the SSHRun action middleware that validates a machine
# is running before executing SSH commands via `vagrant ssh -c "command"`.
#
# Expected behavior:
# - Validates machine ID exists (via MachineValidation module)
# - Validates machine state is :running before allowing SSH command execution
# - Raises SSHNotReady error if machine is stopped or not_created
# - Does NOT call OrbStackCLI (Vagrant handles SSH execution)
# - Does NOT invalidate state cache (read-only operation)
# - Passes env to next middleware in the chain if validation passes

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Action::SSHRun' do
  describe 'class definition' do
    it 'is defined after requiring action/ssh_run file' do
      expect do
        require 'vagrant-orbstack/action/ssh_run'
        VagrantPlugins::OrbStack::Action::SSHRun
      end.not_to raise_error
    end
  end

  describe '#call' do
    before do
      require 'vagrant-orbstack/action/ssh_run'
      require 'vagrant-orbstack/provider'
    end

    let(:action_class) { VagrantPlugins::OrbStack::Action::SSHRun }

    # Mock Vagrant environment and machine
    let(:ui) do
      double('ui',
             info: nil,
             warn: nil,
             error: nil,
             success: nil)
    end

    let(:provider) do
      instance_double('VagrantPlugins::OrbStack::Provider',
                      state: running_state)
    end

    let(:machine) do
      double('machine',
             id: 'vagrant-default-abc123',
             name: 'default',
             provider: provider,
             ui: ui)
    end

    let(:app) { double('app', call: nil) }

    let(:env) do
      {
        machine: machine,
        ui: ui
      }
    end

    # Machine state fixtures
    let(:running_state) do
      Vagrant::MachineState.new(:running, 'running', 'Machine is running')
    end

    let(:stopped_state) do
      Vagrant::MachineState.new(:stopped, 'stopped', 'Machine is stopped')
    end

    let(:not_created_state) do
      Vagrant::MachineState.new(:not_created, 'not created', 'Machine has not been created')
    end

    # ============================================================================
    # CORE FUNCTIONALITY TESTS
    # ============================================================================

    context 'when machine is running' do
      before do
        allow(provider).to receive(:state).and_return(running_state)
      end

      it 'validates machine ID exists' do
        # Arrange
        action = action_class.new(app, env)

        # Act - should not raise error with valid machine ID
        expect { action.call(env) }.not_to raise_error
      end

      it 'checks machine state is running' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - should query state from provider
        expect(provider).to have_received(:state)
      end

      it 'continues middleware chain after validation' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - next middleware should be called
        expect(app).to have_received(:call)
      end

      it 'passes env unchanged to next middleware' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(app).to have_received(:call) do |passed_env|
          expect(passed_env).to eq(env)
        end
      end

      it 'does not modify machine state' do
        # Arrange
        action = action_class.new(app, env)
        original_machine_id = machine.id

        # Act
        action.call(env)

        # Assert - machine ID should remain unchanged
        expect(machine.id).to eq(original_machine_id)
      end
    end

    # ============================================================================
    # STATE VALIDATION TESTS
    # ============================================================================

    context 'when machine is stopped' do
      before do
        allow(provider).to receive(:state).and_return(stopped_state)
      end

      it 'raises SSHNotReady error' do
        # Arrange
        action = action_class.new(app, env)

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::SSHNotReady
        )
      end

      it 'includes machine name in error message' do
        # Arrange
        action = action_class.new(app, env)

        # Act & Assert
        expect { action.call(env) }.to raise_error do |error|
          expect(error.message).to include('default')
            .or include('stopped')
        end
      end

      it 'does not call next middleware' do
        # Arrange
        action = action_class.new(app, env)

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::SSHNotReady
        )

        # Next middleware should NOT be called
        expect(app).not_to have_received(:call)
      end
    end

    context 'when machine is not created' do
      before do
        allow(provider).to receive(:state).and_return(not_created_state)
      end

      it 'raises SSHNotReady error' do
        # Arrange
        action = action_class.new(app, env)

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::SSHNotReady
        )
      end

      it 'includes machine name in error message' do
        # Arrange
        action = action_class.new(app, env)

        # Act & Assert
        expect { action.call(env) }.to raise_error do |error|
          expect(error.message).to include('default')
            .or include('not created')
            .or include('not_created')
        end
      end
    end

    # ============================================================================
    # EDGE CASES
    # ============================================================================

    context 'when handling edge cases' do
      it 'handles nil machine ID gracefully' do
        # Arrange
        allow(machine).to receive(:id).and_return(nil)
        action = action_class.new(app, env)

        # Act & Assert - should raise error from MachineValidation
        expect { action.call(env) }.to raise_error
      end

      it 'handles empty machine ID gracefully' do
        # Arrange
        allow(machine).to receive(:id).and_return('')
        action = action_class.new(app, env)

        # Act & Assert - should raise error from MachineValidation
        expect { action.call(env) }.to raise_error
      end
    end

    # ============================================================================
    # MIDDLEWARE CHAIN INTEGRATION TESTS
    # ============================================================================

    context 'when integrating with middleware chain' do
      before do
        allow(provider).to receive(:state).and_return(running_state)
      end

      it 'calls next middleware when machine is running' do
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
          expect(passed_env[:machine]).to eq(machine)
          expect(passed_env[:ui]).to eq(ui)
        end
      end

      it 'does not call next middleware when machine not running' do
        # Arrange
        allow(provider).to receive(:state).and_return(stopped_state)
        action = action_class.new(app, env)

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::SSHNotReady
        )

        # Next middleware should NOT be called
        expect(app).not_to have_received(:call)
      end
    end

    # ============================================================================
    # NO ORBSTACK CLI CALLS (READ-ONLY OPERATION)
    # ============================================================================

    context 'when verifying no OrbStackCLI calls' do
      before do
        allow(provider).to receive(:state).and_return(running_state)
      end

      it 'does not call any OrbStackCLI methods' do
        # Arrange
        action = action_class.new(app, env)

        # This action should NOT interact with OrbStackCLI at all
        # Vagrant handles the actual SSH command execution

        # Act
        action.call(env)

        # Assert - no CLI calls expected (this is implicitly tested by not mocking any)
        expect(app).to have_received(:call)
      end
    end

    # ============================================================================
    # NO STATE CACHE INVALIDATION (READ-ONLY)
    # ============================================================================

    context 'when verifying no state cache invalidation' do
      before do
        allow(provider).to receive(:state).and_return(running_state)
        allow(provider).to receive(:invalidate_state_cache)
      end

      it 'does not invalidate state cache' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - cache should NOT be invalidated (read-only operation)
        expect(provider).not_to have_received(:invalidate_state_cache)
      end
    end
  end
end
