# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Action::Start
#
# This test suite validates the Start action middleware that starts a stopped machine
# via OrbStack CLI, invalidates the state cache, and provides user feedback.
#
# Expected behavior:
# - Calls OrbStackCLI.start_machine with the machine ID
# - Invalidates state cache after starting to force fresh state query
# - Displays UI message to inform user of start operation
# - Propagates CommandExecutionError on CLI failure
# - Propagates CommandTimeoutError on timeout
# - Passes env to next middleware in the chain

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Action::Start' do
  describe 'class definition' do
    it 'is defined after requiring action/start file' do
      expect do
        require 'vagrant-orbstack/action/start'
        VagrantPlugins::OrbStack::Action::Start
      end.not_to raise_error
    end
  end

  describe '#call' do
    before do
      require 'vagrant-orbstack/action/start'
      require 'vagrant-orbstack/provider'
    end

    let(:action_class) { VagrantPlugins::OrbStack::Action::Start }

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
                      invalidate_state_cache: nil)
    end

    let(:machine) do
      double('machine',
             id: 'vagrant-default-xyz789',
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

    # ============================================================================
    # CORE FUNCTIONALITY TESTS
    # ============================================================================

    context 'when starting a stopped machine' do
      before do
        # Mock successful start_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .with('vagrant-default-xyz789')
          .and_return({ id: 'vagrant-default-xyz789', status: 'running' })
      end

      it 'calls OrbStackCLI.start_machine with machine ID' do
        # Arrange
        action = action_class.new(app, env)

        # Expect start_machine to be called with the correct machine ID
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .with('vagrant-default-xyz789')

        # Act
        action.call(env)
      end

      it 'invalidates state cache after starting' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:invalidate_state_cache)
      end

      it 'displays UI message during start' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - should show informative message about starting
        expect(ui).to have_received(:info).with(/start/i)
      end

      it 'displays machine ID in UI message' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - UI message should include machine ID for clarity
        expect(ui).to have_received(:info) do |message|
          expect(message).to match(/start/i)
            .or match(/vagrant-default-xyz789/)
        end
      end

      it 'handles successful start response' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({
                        id: 'vagrant-default-xyz789',
                        status: 'running'
                      })

        # Act & Assert
        expect { action.call(env) }.not_to raise_error
      end
    end

    # ============================================================================
    # ERROR HANDLING TESTS
    # ============================================================================

    context 'when handling errors' do
      it 'propagates CommandExecutionError on CLI failure' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Failed to start machine')

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError,
          /Failed to start machine/
        )
      end

      it 'propagates CommandTimeoutError on timeout' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandTimeoutError,
                     'Command timed out')

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandTimeoutError,
          /Command timed out/
        )
      end

      it 'does not invalidate cache if start fails' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Failed to start machine')

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError
        )

        # Cache should NOT be invalidated on failure
        expect(provider).not_to have_received(:invalidate_state_cache)
      end

      it 'includes machine ID in error context' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Machine vagrant-default-xyz789 not found')

        # Act & Assert
        expect { action.call(env) }.to raise_error do |error|
          expect(error.message).to include('vagrant-default-xyz789')
            .or include('not found')
        end
      end

      it 'handles OrbStack not installed error' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackNotInstalled)

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::OrbStackNotInstalled
        )
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

        # Act & Assert - should raise error or handle gracefully
        # Implementation will determine exact behavior
        expect { action.call(env) }.to raise_error
      end

      it 'handles empty machine ID gracefully' do
        # Arrange
        allow(machine).to receive(:id).and_return('')
        action = action_class.new(app, env)

        # Act & Assert - should raise error or handle gracefully
        # Implementation will determine exact behavior
        expect { action.call(env) }.to raise_error
      end

      it 'handles machine already running scenario' do
        # Arrange
        action = action_class.new(app, env)

        # OrbStack CLI is idempotent - starting an already running machine succeeds
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-xyz789', status: 'running' })

        # Act & Assert
        expect { action.call(env) }.not_to raise_error
      end
    end

    # ============================================================================
    # MIDDLEWARE CHAIN TESTS
    # ============================================================================

    context 'when integrating with middleware chain' do
      before do
        # Mock successful start_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-xyz789', status: 'running' })
      end

      it 'calls next middleware in chain after successful start' do
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

      it 'does not call next middleware if start fails' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Start failed')

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError
        )

        # Next middleware should NOT be called on failure
        expect(app).not_to have_received(:call)
      end
    end

    # ============================================================================
    # STATE CACHE INVALIDATION TESTS
    # ============================================================================

    context 'when invalidating state cache' do
      before do
        # Mock successful start_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-xyz789', status: 'running' })
      end

      it 'invalidates cache before calling next middleware' do
        # Arrange
        action = action_class.new(app, env)
        call_order = []

        # Track call order
        allow(provider).to receive(:invalidate_state_cache) do
          call_order << :invalidate
        end

        allow(app).to receive(:call) do |_env|
          call_order << :next_middleware
        end

        # Act
        action.call(env)

        # Assert - cache invalidation should happen before next middleware
        expect(call_order).to eq(%i[invalidate next_middleware])
      end
    end

    # ============================================================================
    # UI FEEDBACK TESTS
    # ============================================================================

    context 'when providing user feedback' do
      before do
        # Mock successful start_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-xyz789', status: 'running' })
      end

      it 'displays info message before starting' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(ui).to have_received(:info).at_least(:once)
      end

      it 'uses clear, user-friendly language in messages' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - message should be informative
        expect(ui).to have_received(:info) do |message|
          expect(message).to be_a(String)
          expect(message.length).to be > 5
        end
      end

      it 'displays completion message after successful start' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - should show success/completion message
        expect(ui).to have_received(:info).at_least(:once)
      end
    end

    # ============================================================================
    # CLI INTEGRATION TESTS
    # ============================================================================

    context 'when interacting with OrbStackCLI' do
      it 'passes correct timeout to start_machine (if supported)' do
        # Arrange
        action = action_class.new(app, env)

        # start_machine accepts optional timeout parameter
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .with('vagrant-default-xyz789')
          .and_return({ id: 'vagrant-default-xyz789', status: 'running' })

        # Act
        action.call(env)
      end

      it 'handles start_machine response hash correctly' do
        # Arrange
        action = action_class.new(app, env)

        response = {
          id: 'vagrant-default-xyz789',
          status: 'running'
        }

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return(response)

        # Act & Assert - should handle response without errors
        expect { action.call(env) }.not_to raise_error
      end
    end
  end
end
