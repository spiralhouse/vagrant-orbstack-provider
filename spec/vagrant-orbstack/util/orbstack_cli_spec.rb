# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Util::OrbStackCLI
#
# This test verifies the OrbStack CLI detection and interaction utilities.
#
# Expected behavior:
# - Detects if 'orb' command is available in PATH
# - Retrieves OrbStack version for informational logging
# - Checks if OrbStack is currently running
# - Handles errors gracefully when OrbStack not available
# - Returns nil/false for unavailable operations rather than raising

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Util::OrbStackCLI' do
  describe 'module definition' do
    it 'is defined after requiring util/orbstack_cli file' do
      expect do
        require 'vagrant-orbstack/util/orbstack_cli'
        VagrantPlugins::OrbStack::Util::OrbStackCLI
      end.not_to raise_error
    end
  end

  describe '.available?' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'responds to available? class method' do
      expect(cli_class).to respond_to(:available?)
    end

    context 'when orb command exists in PATH' do
      before do
        # Mock successful 'which orb' command
        # Uses execute_command to check PATH
        allow(cli_class).to receive(:execute_command)
          .with('which orb')
          .and_return(['/usr/local/bin/orb', true])
      end

      it 'returns true' do
        expect(cli_class.available?).to be(true)
      end
    end

    context 'when orb command does not exist in PATH' do
      before do
        # Mock failed 'which orb' command
        allow(cli_class).to receive(:execute_command)
          .with('which orb')
          .and_return(['', false])
      end

      it 'returns false' do
        expect(cli_class.available?).to be(false)
      end
    end

    context 'when PATH check raises an exception' do
      before do
        # Mock exception during which command
        allow(cli_class).to receive(:`).with('which orb 2>/dev/null').and_raise(StandardError, 'Command failed')
      end

      it 'returns false gracefully' do
        expect(cli_class.available?).to be(false)
      end
    end
  end

  describe '.version' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'responds to version class method' do
      expect(cli_class).to respond_to(:version)
    end

    context 'when orb --version succeeds' do
      before do
        # Mock successful version command
        # Example output: "orb version 1.2.3"
        allow(cli_class).to receive(:execute_command)
          .with('orb --version')
          .and_return(['orb version 1.2.3', true])
      end

      it 'returns version string' do
        version = cli_class.version
        expect(version).to be_a(String)
        expect(version).to eq('1.2.3')
      end
    end

    context 'when orb command not available' do
      before do
        # Mock unavailable CLI
        allow(cli_class).to receive(:available?).and_return(false)
      end

      it 'returns nil' do
        expect(cli_class.version).to be_nil
      end
    end

    context 'when orb --version output is unparseable' do
      before do
        # Mock unexpected version output
        allow(cli_class).to receive(:execute_command)
          .with('orb --version')
          .and_return(['Invalid output format', true])
      end

      it 'returns nil' do
        expect(cli_class.version).to be_nil
      end
    end

    context 'when orb --version command fails' do
      before do
        # Mock command failure
        allow(cli_class).to receive(:execute_command)
          .with('orb --version')
          .and_return(['', false])
      end

      it 'returns nil' do
        expect(cli_class.version).to be_nil
      end
    end

    context 'when version check raises an exception' do
      before do
        # Mock exception during version command
        allow(cli_class).to receive(:available?).and_return(true)
        allow(cli_class).to receive(:`).with('orb --version 2>/dev/null').and_raise(StandardError, 'Command failed')
      end

      it 'returns nil gracefully' do
        expect(cli_class.version).to be_nil
      end
    end
  end

  describe '.running?' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'responds to running? class method' do
      expect(cli_class).to respond_to(:running?)
    end

    context 'when orb status indicates running' do
      before do
        # Mock successful status check
        # Example output: "OrbStack is running"
        allow(cli_class).to receive(:execute_command)
          .with('orb status')
          .and_return(['OrbStack is running', true])
      end

      it 'returns true' do
        expect(cli_class.running?).to be(true)
      end
    end

    context 'when orb status indicates not running' do
      before do
        # Mock status check showing not running
        allow(cli_class).to receive(:execute_command)
          .with('orb status')
          .and_return(['OrbStack is not running', false])
      end

      it 'returns false' do
        expect(cli_class.running?).to be(false)
      end
    end

    context 'when orb command not available' do
      before do
        # Mock unavailable CLI
        allow(cli_class).to receive(:available?).and_return(false)
      end

      it 'returns false' do
        expect(cli_class.running?).to be(false)
      end
    end

    context 'when orb status command fails' do
      before do
        # Mock command failure
        allow(cli_class).to receive(:execute_command)
          .with('orb status')
          .and_return(['', false])
      end

      it 'returns false' do
        expect(cli_class.running?).to be(false)
      end
    end

    context 'when status check raises an exception' do
      before do
        # Mock exception during status command
        allow(cli_class).to receive(:available?).and_return(true)
        allow(cli_class).to receive(:`).with('orb status 2>/dev/null').and_raise(StandardError, 'Command failed')
      end

      it 'returns false gracefully' do
        expect(cli_class.running?).to be(false)
      end
    end
  end

  describe 'class method accessibility' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'does not require instantiation for available?' do
      # Should be callable as class method
      expect { cli_class.available? }.not_to raise_error
    end

    it 'does not require instantiation for version' do
      # Should be callable as class method
      allow(cli_class).to receive(:available?).and_return(false)
      expect { cli_class.version }.not_to raise_error
    end

    it 'does not require instantiation for running?' do
      # Should be callable as class method
      allow(cli_class).to receive(:available?).and_return(false)
      expect { cli_class.running? }.not_to raise_error
    end
  end

  describe 'error handling philosophy' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'returns false/nil for detection failures rather than raising' do
      # Mock all methods to fail
      allow(cli_class).to receive(:`).and_raise(StandardError, 'Simulated failure')

      # None of these should raise - they should return false/nil
      expect { cli_class.available? }.not_to raise_error
      expect { cli_class.version }.not_to raise_error
      expect { cli_class.running? }.not_to raise_error

      expect(cli_class.available?).to be(false)
      expect(cli_class.version).to be_nil
      expect(cli_class.running?).to be(false)
    end
  end

  describe 'integration scenarios' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    context 'typical usage flow: check availability before operations' do
      it 'allows checking availability before version' do
        # Mock execute_command for sequential calls
        allow(cli_class).to receive(:execute_command)
          .with('which orb')
          .and_return(['/usr/local/bin/orb', true])
        allow(cli_class).to receive(:execute_command)
          .with('orb --version')
          .and_return(['orb version 1.0.0', true])

        # First check if available
        expect(cli_class.available?).to be(true)

        # Then get version
        expect(cli_class.version).to eq('1.0.0')
      end

      it 'allows checking running status after availability check' do
        # Mock execute_command for sequential calls
        allow(cli_class).to receive(:execute_command)
          .with('which orb')
          .and_return(['/usr/local/bin/orb', true])
        allow(cli_class).to receive(:execute_command)
          .with('orb status')
          .and_return(['OrbStack is running', true])

        # First check if available
        expect(cli_class.available?).to be(true)

        # Then check if running
        expect(cli_class.running?).to be(true)
      end
    end

    context 'when OrbStack not installed at all' do
      before do
        # Stub all possible orb commands to simulate CLI not installed
        allow(cli_class).to receive(:execute_command)
          .and_return(['', false])
      end

      it 'returns consistent false/nil values across all checks' do
        expect(cli_class.available?).to be(false)
        expect(cli_class.version).to be_nil
        expect(cli_class.running?).to be(false)
      end
    end
  end
end
