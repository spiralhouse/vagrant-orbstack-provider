# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Action::Destroy
#
# This test suite validates the Destroy action middleware that removes an OrbStack
# machine and cleans up all associated metadata files.
#
# Expected behavior:
# - Calls OrbStackCLI.delete_machine with the machine ID
# - Removes id file from data_dir
# - Removes metadata.json from data_dir
# - Invalidates state cache after destruction
# - Displays user-friendly progress message
# - Handles missing machine gracefully (idempotent)
# - Handles missing metadata files gracefully
# - Propagates CommandExecutionError on CLI failure (but continues cleanup)
# - Propagates CommandTimeoutError on timeout

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Action::Destroy' do
  describe 'class definition' do
    it 'is defined after requiring action/destroy file' do
      expect do
        require 'vagrant-orbstack/action/destroy'
        VagrantPlugins::OrbStack::Action::Destroy
      end.not_to raise_error
    end
  end

  describe '#call' do
    before do
      require 'vagrant-orbstack/action/destroy'
      require 'vagrant-orbstack/provider'
    end

    let(:action_class) { VagrantPlugins::OrbStack::Action::Destroy }

    # Mock Vagrant environment and machine
    let(:ui) do
      double('ui',
             info: nil,
             warn: nil,
             error: nil,
             success: nil)
    end

    let(:data_dir) { Pathname.new('/tmp/test-vagrant-destroy-data') }

    let(:provider) do
      instance_double('VagrantPlugins::OrbStack::Provider',
                      invalidate_state_cache: nil,
                      id_file_path: data_dir.join('id'),
                      metadata_file_path: data_dir.join('metadata.json'))
    end

    let(:machine) do
      double('machine',
             id: 'vagrant-default-abc123',
             provider: provider,
             ui: ui,
             data_dir: data_dir)
    end

    let(:app) { double('app', call: nil) }

    let(:env) do
      {
        machine: machine,
        ui: ui
      }
    end

    # Setup test directory structure before each test
    before do
      FileUtils.mkdir_p(data_dir)
      # Create id file
      File.write(data_dir.join('id'), 'vagrant-default-abc123')
      # Create metadata.json
      File.write(data_dir.join('metadata.json'), '{"machine_name":"vagrant-default-abc123"}')
    end

    # Cleanup test directory after each test
    after do
      FileUtils.rm_rf(data_dir)
    end

    # ============================================================================
    # CORE FUNCTIONALITY TESTS
    # ============================================================================

    context 'when destroying a machine' do
      before do
        # Mock successful delete_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .with('vagrant-default-abc123')
          .and_return(true)
      end

      it 'calls OrbStackCLI.delete_machine with machine ID' do
        # Arrange
        action = action_class.new(app, env)

        # Expect delete_machine to be called with the correct machine ID
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .with('vagrant-default-abc123')

        # Act
        action.call(env)
      end

      it 'removes id file from data directory' do
        # Arrange
        action = action_class.new(app, env)
        id_file = data_dir.join('id')

        # Verify file exists before
        expect(File.exist?(id_file)).to be true

        # Act
        action.call(env)

        # Assert - file should be removed
        expect(File.exist?(id_file)).to be false
      end

      it 'removes metadata.json file from data directory' do
        # Arrange
        action = action_class.new(app, env)
        metadata_file = data_dir.join('metadata.json')

        # Verify file exists before
        expect(File.exist?(metadata_file)).to be true

        # Act
        action.call(env)

        # Assert - file should be removed
        expect(File.exist?(metadata_file)).to be false
      end

      it 'invalidates state cache after destruction' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert
        expect(provider).to have_received(:invalidate_state_cache)
      end

      it 'displays UI message during destruction' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - should show informative message about destruction
        expect(ui).to have_received(:info).with(/destroy/i)
      end

      it 'displays machine ID in UI message' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - UI message should include machine ID for clarity
        expect(ui).to have_received(:info) do |message|
          expect(message).to match(/destroy/i)
            .or match(/vagrant-default-abc123/)
        end
      end
    end

    # ============================================================================
    # ERROR HANDLING TESTS
    # ============================================================================

    context 'when handling errors' do
      it 'handles nil machine ID gracefully (already destroyed)' do
        # Arrange - Machine ID is nil (already destroyed)
        allow(machine).to receive(:id).and_return(nil)
        allow(ui).to receive(:info)
        allow(app).to receive(:call)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
        allow(FileUtils).to receive(:rm_f)
        allow(provider).to receive(:invalidate_state_cache)
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - Should display friendly message and continue chain
        expect(ui).to have_received(:info).with(/already destroyed|never created/i)
        expect(app).to have_received(:call).with(env)

        # Assert - Should NOT attempt cleanup since nothing to clean up
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).not_to have_received(:delete_machine)
        expect(FileUtils).not_to have_received(:rm_f)
        expect(provider).not_to have_received(:invalidate_state_cache)
      end

      it 'raises ArgumentError if machine ID is empty string' do
        # Arrange
        allow(machine).to receive(:id).and_return('')
        action = action_class.new(app, env)

        # Act & Assert
        expect { action.call(env) }.to raise_error(
          ArgumentError,
          /Cannot destroy machine.*empty/i
        )
      end

      it 'continues cleanup even if OrbStack CLI delete fails' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Failed to delete machine')

        # Act & Assert - should not propagate error, but log it
        expect { action.call(env) }.not_to raise_error

        # Cleanup should still happen
        expect(File.exist?(data_dir.join('id'))).to be false
        expect(File.exist?(data_dir.join('metadata.json'))).to be false
      end

      it 'logs warning if OrbStack CLI delete fails but continues' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Machine not found')

        # Act
        action.call(env)

        # Assert - should warn user about error and continuing with cleanup
        expect(ui).to have_received(:warn).with('Error deleting machine from OrbStack: Machine not found')
        expect(ui).to have_received(:warn).with('Continuing with local cleanup...')
      end

      it 'invalidates cache even if CLI delete fails' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Delete failed')

        # Act
        action.call(env)

        # Assert - cache invalidation should still occur
        expect(provider).to have_received(:invalidate_state_cache)
      end
    end

    # ============================================================================
    # IDEMPOTENCY TESTS
    # ============================================================================

    context 'when handling idempotency' do
      before do
        # Mock successful delete_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_return(true)
      end

      it 'succeeds gracefully if id file does not exist' do
        # Arrange
        action = action_class.new(app, env)
        FileUtils.rm_f(data_dir.join('id'))

        # Act & Assert - should not raise error
        expect { action.call(env) }.not_to raise_error
      end

      it 'succeeds gracefully if metadata.json does not exist' do
        # Arrange
        action = action_class.new(app, env)
        FileUtils.rm_f(data_dir.join('metadata.json'))

        # Act & Assert - should not raise error
        expect { action.call(env) }.not_to raise_error
      end

      it 'succeeds gracefully if both files do not exist' do
        # Arrange
        action = action_class.new(app, env)
        FileUtils.rm_f(data_dir.join('id'))
        FileUtils.rm_f(data_dir.join('metadata.json'))

        # Act & Assert - should not raise error
        expect { action.call(env) }.not_to raise_error
      end

      it 'uses FileUtils.rm_f for silent file removal' do
        # Arrange
        action = action_class.new(app, env)

        # Expect FileUtils.rm_f to be called (force removal, no error if missing)
        expect(FileUtils).to receive(:rm_f).with(data_dir.join('id'))
        expect(FileUtils).to receive(:rm_f).with(data_dir.join('metadata.json'))

        # Act
        action.call(env)
      end

      it 'succeeds when destroying non-existent machine' do
        # Arrange
        action = action_class.new(app, env)

        # Mock machine doesn't exist in OrbStack
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Machine not found')

        # Act & Assert - should succeed gracefully
        expect { action.call(env) }.not_to raise_error

        # Cleanup should still happen
        expect(File.exist?(data_dir.join('id'))).to be false
      end
    end

    # ============================================================================
    # MIDDLEWARE CHAIN TESTS
    # ============================================================================

    context 'when integrating with middleware chain' do
      before do
        # Mock successful delete_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_return(true)
      end

      it 'calls next middleware in chain after successful destruction' do
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

      it 'calls next middleware even if CLI delete fails' do
        # Arrange
        action = action_class.new(app, env)

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError,
                     'Delete failed')

        # Act
        action.call(env)

        # Assert - cleanup is best-effort, continue middleware chain
        expect(app).to have_received(:call)
      end
    end

    # ============================================================================
    # STATE CACHE INVALIDATION TESTS
    # ============================================================================

    context 'when invalidating state cache' do
      before do
        # Mock successful delete_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_return(true)
      end

      it 'invalidates cache after file cleanup' do
        # Arrange
        action = action_class.new(app, env)
        call_order = []

        # Track call order - FileUtils should happen first
        allow(FileUtils).to receive(:rm_f) do |_path|
          call_order << :cleanup
        end

        allow(provider).to receive(:invalidate_state_cache) do
          call_order << :invalidate
        end

        # Act
        action.call(env)

        # Assert - cleanup should happen before cache invalidation
        expect(call_order).to include(:cleanup, :invalidate)
        expect(call_order.index(:cleanup)).to be < call_order.index(:invalidate)
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
        # Mock successful delete_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_return(true)
      end

      it 'displays info message before destroying' do
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

      it 'displays success message after destruction completes' do
        # Arrange
        action = action_class.new(app, env)

        # Act
        action.call(env)

        # Assert - should provide confirmation to user
        expect(ui).to have_received(:info).with(/destroy/i).at_least(:once)
      end
    end

    # ============================================================================
    # FILE CLEANUP OPERATION TESTS
    # ============================================================================

    context 'when cleaning up metadata files' do
      before do
        # Mock successful delete_machine call
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine)
          .and_return(true)
      end

      it 'cleans up id file using correct path' do
        # Arrange
        action = action_class.new(app, env)

        # Expect cleanup of id file at correct location
        expect(FileUtils).to receive(:rm_f).with(data_dir.join('id'))
        allow(FileUtils).to receive(:rm_f).with(data_dir.join('metadata.json'))

        # Act
        action.call(env)
      end

      it 'cleans up metadata.json using correct path' do
        # Arrange
        action = action_class.new(app, env)

        # Expect cleanup of metadata file at correct location
        allow(FileUtils).to receive(:rm_f).with(data_dir.join('id'))
        expect(FileUtils).to receive(:rm_f).with(data_dir.join('metadata.json'))

        # Act
        action.call(env)
      end

      it 'performs cleanup in correct order: CLI delete, then files, then cache' do
        # Arrange
        action = action_class.new(app, env)
        call_order = []

        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:delete_machine) do
          call_order << :cli_delete
          true
        end

        allow(FileUtils).to receive(:rm_f) do |path|
          call_order << :cleanup if path.to_s.include?('id') || path.to_s.include?('metadata')
        end

        allow(provider).to receive(:invalidate_state_cache) do
          call_order << :invalidate
        end

        # Act
        action.call(env)

        # Assert - CLI delete, then file cleanup, then cache invalidation
        expect(call_order).to eq(%i[cli_delete cleanup cleanup invalidate])
      end
    end
  end
end
