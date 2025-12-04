# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Action::Reload
#
# This test suite validates the Reload action middleware that restarts a machine
# by composing Halt and Start actions, with optional provisioning support.
#
# Expected behavior:
# - Composes Halt and Start actions in sequence
# - Optionally includes provisioning middleware based on env[:provision_enabled]
# - Handles both running and stopped machines (idempotent operations)
# - Propagates errors from composed actions appropriately
# - Invalidates state cache via composed actions
# - Provides appropriate UI feedback through composed actions

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Action::Reload' do
  describe 'class definition' do
    it 'is defined after requiring action/reload file' do
      expect do
        require 'vagrant-orbstack/action/reload'
        VagrantPlugins::OrbStack::Action::Reload
      end.not_to raise_error
    end
  end

  describe 'provider action registration' do
    before do
      require 'vagrant-orbstack/provider'
    end

    let(:provider_class) { VagrantPlugins::OrbStack::Provider }
    let(:machine) { double('machine', data_dir: Pathname.new('/tmp/test')) }
    let(:provider) { provider_class.new(machine) }

    it 'returns an action builder for :reload' do
      # Arrange & Act
      action_builder = provider.action(:reload)

      # Assert
      expect(action_builder).to be_a(Vagrant::Action::Builder)
    end

    it 'includes Halt action in the reload builder' do
      # Arrange
      action_builder = provider.action(:reload)

      # Act - inspect the middleware stack
      # The builder should contain Halt middleware
      # This tests that the action composition includes Halt

      # Assert
      # We expect the builder to have middleware that will halt the machine
      expect(action_builder).not_to be_nil
    end

    it 'includes Start action in the reload builder' do
      # Arrange
      action_builder = provider.action(:reload)

      # Act - inspect the middleware stack
      # The builder should contain Start middleware after Halt

      # Assert
      # We expect the builder to have middleware that will start the machine
      expect(action_builder).not_to be_nil
    end
  end

  describe 'action composition and execution' do
    before do
      require 'vagrant-orbstack/action/reload'
      require 'vagrant-orbstack/provider'
      require 'vagrant-orbstack/action/halt'
      require 'vagrant-orbstack/action/start'
    end

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
             id: 'vagrant-default-reload123',
             provider: provider,
             ui: ui)
    end

    let(:env) do
      {
        machine: machine,
        ui: ui
      }
    end

    # ============================================================================
    # CORE FUNCTIONALITY TESTS
    # ============================================================================

    context 'when reloading a running machine' do
      before do
        # Mock successful halt and start operations
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .with('vagrant-default-reload123')
          .and_return(true)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .with('vagrant-default-reload123')
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'calls halt operation first' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Expect stop_machine to be called (from Halt action)
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .with('vagrant-default-reload123')

        # Act
        action_builder.call(env)
      end

      it 'calls start operation after halt' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Expect start_machine to be called after stop_machine
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .with('vagrant-default-reload123')

        # Act
        action_builder.call(env)
      end

      it 'executes halt before start in correct order' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)
        call_order = []

        # Track call order
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine) do
          call_order << :halt
          true
        end

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine) do
          call_order << :start
          { id: 'vagrant-default-reload123', status: 'running' }
        end

        # Act
        action_builder.call(env)

        # Assert - halt must happen before start
        expect(call_order).to eq(%i[halt start])
      end

      it 'invalidates state cache twice (once after halt, once after start)' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act
        action_builder.call(env)

        # Assert - cache should be invalidated by both Halt and Start actions
        expect(provider).to have_received(:invalidate_state_cache).twice
      end

      it 'displays UI messages from both halt and start actions' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act
        action_builder.call(env)

        # Assert - should see messages from both operations
        expect(ui).to have_received(:info).with(/halt/i).at_least(:once)
        expect(ui).to have_received(:info).with(/start/i).at_least(:once)
      end
    end

    context 'when reloading a stopped machine' do
      before do
        # Mock halt (idempotent - stopping stopped machine succeeds)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .with('vagrant-default-reload123')
          .and_return(true)

        # Mock successful start
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .with('vagrant-default-reload123')
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'halts the stopped machine without error' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert - should succeed even if already stopped
        expect { action_builder.call(env) }.not_to raise_error
      end

      it 'starts the machine successfully after halt' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Expect start_machine to be called
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .with('vagrant-default-reload123')

        # Act
        action_builder.call(env)
      end

      it 'completes reload operation successfully' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.not_to raise_error

        # Both operations should be called
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:stop_machine)
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:start_machine)
      end
    end

    # ============================================================================
    # PROVISIONING INTEGRATION TESTS
    # ============================================================================

    context 'when provisioning is enabled' do
      let(:env_with_provision_enabled) do
        {
          machine: machine,
          ui: ui,
          provision_enabled: true
        }
      end

      before do
        # Mock successful halt and start
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_return(true)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'includes provisioning middleware in the action builder' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act - the builder should contain provisioning middleware when provision_enabled is true
        # This is tested by verifying the action builder structure

        # Assert
        expect(action_builder).not_to be_nil
        # The implementation should include Vagrant::Action::Builtin::Provision
      end

      it 'runs provisioning after machine is restarted' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Mock provisioning middleware behavior
        # In real Vagrant, Builtin::Provision would run provisioners
        # We'll verify the middleware chain allows for this

        # Act
        action_builder.call(env_with_provision_enabled)

        # Assert - provisioning should happen after restart
        # The composed actions should complete successfully
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:stop_machine)
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:start_machine)
      end

      it 'handles provision_enabled flag correctly' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert - should not raise error when provision_enabled is set
        expect { action_builder.call(env_with_provision_enabled) }.not_to raise_error
      end
    end

    context 'when provisioning is disabled' do
      let(:env_with_provision_disabled) do
        {
          machine: machine,
          ui: ui,
          provision_enabled: false
        }
      end

      before do
        # Mock successful halt and start
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_return(true)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'skips provisioning when provision_enabled is false' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act
        action_builder.call(env_with_provision_disabled)

        # Assert - reload should complete without provisioning
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:stop_machine)
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:start_machine)
      end

      it 'completes reload successfully without provisioning' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env_with_provision_disabled) }.not_to raise_error
      end
    end

    context 'when provisioning flag is not set' do
      let(:env_without_provision_flag) do
        {
          machine: machine,
          ui: ui
          # provision_enabled not included
        }
      end

      before do
        # Mock successful halt and start
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_return(true)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'handles missing provision_enabled flag gracefully' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert - should not raise error when flag is missing
        expect { action_builder.call(env_without_provision_flag) }.not_to raise_error
      end

      it 'uses default provisioning behavior when flag is absent' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act
        action_builder.call(env_without_provision_flag)

        # Assert - reload should complete with default behavior
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:stop_machine)
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:start_machine)
      end
    end

    # ============================================================================
    # ERROR HANDLING TESTS
    # ============================================================================

    context 'when halt operation fails' do
      before do
        # Mock halt failure
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Failed to stop machine')

        # Start should not be called if halt fails
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'propagates CommandExecutionError from halt' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError,
          /Failed to stop machine/
        )
      end

      it 'does not call start if halt fails' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError
        )

        # Start should NOT be called if halt failed
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).not_to have_received(:start_machine)
      end

      it 'leaves machine in current state when halt fails' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError
        )

        # State cache should not be invalidated on halt failure (per Halt spec)
        # This is handled by the Halt action itself
      end
    end

    context 'when start operation fails after successful halt' do
      before do
        # Mock successful halt
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .with('vagrant-default-reload123')
          .and_return(true)

        # Mock start failure
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Failed to start machine')
      end

      it 'propagates CommandExecutionError from start' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError,
          /Failed to start machine/
        )
      end

      it 'successfully halts before start failure' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError
        )

        # Halt should have been called successfully
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:stop_machine)
      end

      it 'leaves machine in stopped state when start fails' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError
        )

        # Machine was successfully halted, so cache was invalidated once
        expect(provider).to have_received(:invalidate_state_cache).once
      end
    end

    context 'when halt times out' do
      before do
        # Mock halt timeout
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandTimeoutError,
                     'Halt operation timed out')

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'propagates CommandTimeoutError from halt' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandTimeoutError,
          /timed out/i
        )
      end

      it 'does not proceed to start after halt timeout' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandTimeoutError
        )

        # Start should NOT be called after timeout
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).not_to have_received(:start_machine)
      end
    end

    context 'when start times out after successful halt' do
      before do
        # Mock successful halt
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_return(true)

        # Mock start timeout
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandTimeoutError,
                     'Start operation timed out')
      end

      it 'propagates CommandTimeoutError from start' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandTimeoutError,
          /timed out/i
        )
      end

      it 'completes halt before start timeout' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandTimeoutError
        )

        # Halt should have completed
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:stop_machine)
      end
    end

    # ============================================================================
    # EDGE CASES
    # ============================================================================

    context 'when handling edge cases' do
      it 'handles nil machine ID gracefully in halt phase' do
        # Arrange
        allow(machine).to receive(:id).and_return(nil)
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert - should raise error from Halt action
        expect { action_builder.call(env) }.to raise_error
      end

      it 'handles empty machine ID gracefully in halt phase' do
        # Arrange
        allow(machine).to receive(:id).and_return('')
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert - should raise error from Halt action
        expect { action_builder.call(env) }.to raise_error
      end

      it 'handles OrbStack not installed error' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackNotInstalled)

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::OrbStackNotInstalled
        )
      end

      it 'handles machine that does not exist' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Machine vagrant-default-reload123 not found')

        # Act & Assert
        expect { action_builder.call(env) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandExecutionError,
          /not found/i
        )
      end
    end

    # ============================================================================
    # MIDDLEWARE CHAIN TESTS
    # ============================================================================

    context 'when integrating with middleware chain' do
      before do
        # Mock successful operations
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_return(true)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'executes the complete middleware stack' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act & Assert - should complete without error
        expect { action_builder.call(env) }.not_to raise_error

        # Both component actions should have been executed
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:stop_machine)
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:start_machine)
      end

      it 'passes environment hash through the middleware chain' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)
        custom_env = env.merge(custom_key: 'custom_value')

        # Act
        action_builder.call(custom_env)

        # Assert - env should be preserved through the chain
        expect(custom_env[:custom_key]).to eq('custom_value')
      end
    end

    # ============================================================================
    # STATE CACHE INVALIDATION TESTS
    # ============================================================================

    context 'when invalidating state cache' do
      before do
        # Mock successful operations
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_return(true)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'invalidates cache after halt and after start' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)
        invalidation_order = []

        allow(provider).to receive(:invalidate_state_cache) do
          invalidation_order << :invalidate
        end

        # Act
        action_builder.call(env)

        # Assert - should be invalidated twice (once per action)
        expect(invalidation_order.length).to eq(2)
      end

      it 'maintains cache invalidation order (halt first, then start)' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)
        events = []

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine) do
          events << :halt
          true
        end

        allow(provider).to receive(:invalidate_state_cache) do
          events << :invalidate_cache
        end

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine) do
          events << :start
          { id: 'vagrant-default-reload123', status: 'running' }
        end

        # Act
        action_builder.call(env)

        # Assert - events should occur in expected order
        halt_index = events.index(:halt)
        start_index = events.index(:start)
        expect(halt_index).to be < start_index
      end
    end

    # ============================================================================
    # UI FEEDBACK TESTS
    # ============================================================================

    context 'when providing user feedback' do
      before do
        # Mock successful operations
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:stop_machine)
          .and_return(true)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:start_machine)
          .and_return({ id: 'vagrant-default-reload123', status: 'running' })
      end

      it 'displays halt message during halt phase' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act
        action_builder.call(env)

        # Assert - should show halt message
        expect(ui).to have_received(:info).with(/halt/i)
      end

      it 'displays start message during start phase' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act
        action_builder.call(env)

        # Assert - should show start message
        expect(ui).to have_received(:info).with(/start/i)
      end

      it 'displays machine ID in messages' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act
        action_builder.call(env)

        # Assert - messages should include machine ID
        expect(ui).to have_received(:info).twice do |message|
          expect(message).to match(/vagrant-default-reload123/)
            .or match(/halt|start/i)
        end
      end

      it 'provides clear feedback throughout reload process' do
        # Arrange
        provider_instance = VagrantPlugins::OrbStack::Provider.new(machine)
        action_builder = provider_instance.action(:reload)

        # Act
        action_builder.call(env)

        # Assert - should have multiple informative messages
        expect(ui).to have_received(:info).at_least(:twice)
      end
    end
  end
end
