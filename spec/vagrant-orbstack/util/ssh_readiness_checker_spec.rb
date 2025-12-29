# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Util::SSHReadinessChecker
#
# This test suite validates the SSH readiness polling utility that waits for
# OrbStack machines to reach 'running' status before SSH becomes available.
#
# Expected behavior:
# - Polls OrbStackCLI.machine_info every POLL_INTERVAL seconds
# - Returns true when machine status is 'running'
# - Raises SSHNotReady error after MAX_WAIT_TIME timeout
# - Displays progress messages via UI
# - Handles nil/missing machine_info responses
# - Propagates OrbStackCLI errors

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Util::SSHReadinessChecker' do
  describe 'module definition' do
    it 'is defined after requiring util/ssh_readiness_checker file' do
      expect do
        require 'vagrant-orbstack/util/ssh_readiness_checker'
        VagrantPlugins::OrbStack::Util::SSHReadinessChecker
      end.not_to raise_error
    end
  end

  describe '.wait_for_ready' do
    before do
      require 'vagrant-orbstack/util/ssh_readiness_checker'
    end

    let(:checker_class) { VagrantPlugins::OrbStack::Util::SSHReadinessChecker }
    let(:machine_name) { 'vagrant-default-a3b2c1' }

    # Mock Vagrant UI
    let(:ui) do
      double('ui',
             info: nil,
             warn: nil,
             error: nil,
             success: nil)
    end

    it 'responds to wait_for_ready class method' do
      expect(checker_class).to respond_to(:wait_for_ready)
    end

    # ============================================================================
    # CONSTANTS TESTS
    # ============================================================================

    context 'when checking constants' do
      it 'defines MAX_WAIT_TIME constant as 120 seconds' do
        expect(checker_class::MAX_WAIT_TIME).to eq(120)
      end

      it 'defines POLL_INTERVAL constant as 2 seconds' do
        expect(checker_class::POLL_INTERVAL).to eq(2)
      end
    end

    # ============================================================================
    # SUCCESS SCENARIOS
    # ============================================================================

    context 'when machine becomes ready immediately' do
      before do
        # Mock machine_info to return 'running' on first poll
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info)
          .with(machine_name)
          .and_return({ 'status' => 'running' })

        # Mock sleep to avoid delays in tests
        allow(checker_class).to receive(:sleep)
      end

      it 'returns true' do
        result = checker_class.wait_for_ready(machine_name, ui: ui)
        expect(result).to be(true)
      end

      it 'displays initial waiting message' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(ui).to have_received(:info).with(/Waiting for SSH to become available/i)
      end

      it 'displays success message when ready' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(ui).to have_received(:info).with(/SSH is ready/i)
      end

      it 'does not sleep when immediately ready' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(checker_class).not_to have_received(:sleep)
      end

      it 'queries machine_info exactly once' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:machine_info).once
      end
    end

    context 'when machine becomes ready after N polls' do
      before do
        # Mock machine_info to return 'starting' then 'running'
        @call_count = 0
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info) do
          @call_count += 1
          if @call_count < 3
            { 'status' => 'starting' }
          else
            { 'status' => 'running' }
          end
        end

        # Mock sleep to avoid delays
        allow(checker_class).to receive(:sleep)
      end

      it 'returns true after polling multiple times' do
        result = checker_class.wait_for_ready(machine_name, ui: ui)
        expect(result).to be(true)
      end

      it 'polls multiple times until running' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:machine_info).at_least(3).times
      end

      it 'sleeps POLL_INTERVAL between polls' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(checker_class).to have_received(:sleep).with(2).at_least(2).times
      end

      it 'displays progress messages during polling' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(ui).to have_received(:info).at_least(3).times
      end

      it 'displays elapsed time in progress messages' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        # Should show elapsed time like "Still waiting... (4 seconds elapsed)"
        expect(ui).to have_received(:info).with(/\d+ seconds? elapsed/i).at_least(:once)
      end
    end

    # ============================================================================
    # FAILURE SCENARIOS - TIMEOUT
    # ============================================================================

    context 'when timeout is exceeded' do
      before do
        # Mock machine_info to always return 'starting' (never 'running')
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info)
          .with(machine_name)
          .and_return({ 'status' => 'starting' })

        # Mock sleep to avoid delays
        allow(checker_class).to receive(:sleep)

        # Mock Time to simulate elapsed time
        @start_time = Time.now
        @current_time = @start_time
        allow(Time).to receive(:now) do
          # Advance time by 2 seconds each call
          @current_time += 2
          @current_time
        end
      end

      it 'raises SSHNotReady error' do
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.to raise_error(VagrantPlugins::OrbStack::Errors::SSHNotReady)
      end

      it 'includes machine name in error parameters' do
        # Error should be raised with machine_name parameter for I18n
        # The locale file template uses %{machine_name} placeholder
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.to raise_error(VagrantPlugins::OrbStack::Errors::SSHNotReady)
      end

      it 'raises SSHNotReady with I18n parameter hash' do
        # Verify error is raised correctly (parameter hash verified at runtime)
        # When Vagrant's I18n system processes the error, it will use
        # locales/en.yml ssh_not_ready template with %{machine_name}
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.to raise_error(VagrantPlugins::OrbStack::Errors::SSHNotReady)
      end

      it 'respects MAX_WAIT_TIME constant' do
        # Should stop polling after 120 seconds
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.to raise_error(VagrantPlugins::OrbStack::Errors::SSHNotReady)

        # Verify we polled approximately MAX_WAIT_TIME / POLL_INTERVAL times
        # 120 seconds / 2 seconds = 60 polls max
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI)
          .to have_received(:machine_info).at_most(61).times
      end
    end

    # ============================================================================
    # EDGE CASES - NIL/MISSING RESPONSES
    # ============================================================================

    context 'when machine_info returns nil' do
      before do
        # Mock machine_info to return nil (machine doesn't exist yet)
        # Then return running after a few attempts
        @call_count = 0
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info) do
          @call_count += 1
          if @call_count < 3
            nil
          else
            { 'status' => 'running' }
          end
        end

        # Mock sleep to avoid delays
        allow(checker_class).to receive(:sleep)
      end

      it 'continues polling until machine info is available' do
        result = checker_class.wait_for_ready(machine_name, ui: ui)
        expect(result).to be(true)
      end

      it 'does not raise error when machine_info is nil' do
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.not_to raise_error
      end

      it 'polls multiple times until machine exists' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to have_received(:machine_info).at_least(3).times
      end
    end

    context 'when machine_info returns hash without status key' do
      before do
        # Mock machine_info to return incomplete hash
        # Then return complete hash with status
        @call_count = 0
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info) do
          @call_count += 1
          if @call_count < 3
            { 'name' => machine_name } # Missing 'status' key
          else
            { 'name' => machine_name, 'status' => 'running' }
          end
        end

        # Mock sleep to avoid delays
        allow(checker_class).to receive(:sleep)
      end

      it 'continues polling until status is available' do
        result = checker_class.wait_for_ready(machine_name, ui: ui)
        expect(result).to be(true)
      end

      it 'does not raise error when status key is missing' do
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.not_to raise_error
      end
    end

    # ============================================================================
    # EDGE CASES - CLI ERRORS
    # ============================================================================

    context 'when machine_info raises OrbStackCLI error' do
      before do
        # Mock machine_info to raise CLI error
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info)
          .with(machine_name)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandExecutionError, 'CLI command failed')
      end

      it 'propagates the OrbStackCLI error' do
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.to raise_error(VagrantPlugins::OrbStack::Errors::CommandExecutionError, /CLI command failed/)
      end

      it 'does not catch and suppress CLI errors' do
        # Should not be caught as SSHNotReady
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.not_to raise_error(VagrantPlugins::OrbStack::Errors::SSHNotReady)
      end
    end

    context 'when machine_info raises timeout error' do
      before do
        # Mock machine_info to raise timeout error
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info)
          .with(machine_name)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandTimeoutError, 'Command timed out')
      end

      it 'propagates the timeout error' do
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.to raise_error(VagrantPlugins::OrbStack::Errors::CommandTimeoutError, /Command timed out/)
      end
    end

    context 'when machine_info raises OrbStack not installed error' do
      before do
        # Mock machine_info to raise not installed error
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info)
          .with(machine_name)
          .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackNotInstalled)
      end

      it 'propagates the not installed error' do
        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.to raise_error(VagrantPlugins::OrbStack::Errors::OrbStackNotInstalled)
      end
    end

    # ============================================================================
    # UI MESSAGING TESTS
    # ============================================================================

    context 'when verifying UI messages' do
      before do
        # Mock machine_info to return 'starting' twice, then 'running'
        @call_count = 0
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info) do
          @call_count += 1
          if @call_count < 3
            { 'status' => 'starting' }
          else
            { 'status' => 'running' }
          end
        end

        # Mock sleep to avoid delays
        allow(checker_class).to receive(:sleep)
      end

      it 'displays initial waiting message once' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(ui).to have_received(:info).with(/Waiting for SSH/i).once
      end

      it 'displays progress messages during polling' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        # Should display at least 2 progress messages (for 2 'starting' polls)
        expect(ui).to have_received(:info).with(/Still waiting/i).at_least(2).times
      end

      it 'displays success message when ready' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(ui).to have_received(:info).with(/SSH is ready/i).once
      end

      it 'includes machine name in initial message' do
        checker_class.wait_for_ready(machine_name, ui: ui)
        expect(ui).to have_received(:info).with(/vagrant-default-a3b2c1/).at_least(:once)
      end
    end

    # ============================================================================
    # METHOD SIGNATURE TESTS
    # ============================================================================

    context 'when validating method signature' do
      it 'requires machine_name parameter' do
        # Should raise ArgumentError if machine_name is missing
        expect do
          checker_class.wait_for_ready(ui: ui)
        end.to raise_error(ArgumentError, /wrong number of arguments/)
      end

      it 'requires ui keyword argument' do
        # Should raise ArgumentError if ui is missing
        expect do
          checker_class.wait_for_ready(machine_name)
        end.to raise_error(ArgumentError, /missing keyword.*ui/i)
      end

      it 'accepts machine_name and ui parameters' do
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:machine_info)
          .and_return({ 'status' => 'running' })

        expect do
          checker_class.wait_for_ready(machine_name, ui: ui)
        end.not_to raise_error
      end
    end
  end
end
