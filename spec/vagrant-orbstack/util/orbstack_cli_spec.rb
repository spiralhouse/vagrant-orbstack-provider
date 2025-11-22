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

  # ============================================================================
  # LOGGER INITIALIZATION TESTS (SPI-1134)
  # ============================================================================
  #
  # These tests verify that the OrbStackCLI utility class initializes a logger
  # for debugging CLI interactions and command execution.
  #
  # Reference: SPI-1134 - Logging infrastructure and debug output
  # ============================================================================

  describe 'logger initialization' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'has a logger class instance variable' do
      # OrbStackCLI should have a @@logger class variable or @logger class instance variable
      logger = cli_class.instance_variable_get(:@logger)
      expect(logger).not_to be_nil
    end

    it 'logger is a Log4r::Logger instance' do
      # Logger should be a Log4r::Logger instance
      logger = cli_class.instance_variable_get(:@logger)
      expect(logger).to be_a(Log4r::Logger)
    end

    it 'logger uses correct namespace vagrant_orbstack::util' do
      # Logger should use Vagrant naming convention: vagrant_orbstack::util
      logger = cli_class.instance_variable_get(:@logger)
      expect(logger.name).to eq('vagrant_orbstack::util')
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
          .and_return(['/usr/local/bin/orb', '', true])
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
          .and_return(['', '', false])
      end

      it 'returns false' do
        expect(cli_class.available?).to be(false)
      end
    end

    context 'when PATH check raises an exception' do
      before do
        # Mock exception during Open3.capture3 (execute_command catches StandardError and returns false)
        allow(Open3).to receive(:capture3)
          .with('which orb')
          .and_raise(StandardError, 'Command failed')
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
          .and_return(['orb version 1.2.3', '', true])
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
          .and_return(['Invalid output format', '', true])
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
          .and_return(['', '', false])
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
          .and_return(['OrbStack is running', '', true])
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
          .and_return(['OrbStack is not running', '', false])
      end

      it 'returns false' do
        expect(cli_class.running?).to be(false)
      end
    end

    context 'when orb command not available' do
      before do
        # Mock unavailable CLI - command fails
        allow(cli_class).to receive(:execute_command)
          .with('orb status')
          .and_return(['', '', false])
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
          .and_return(['', '', false])
      end

      it 'returns false' do
        expect(cli_class.running?).to be(false)
      end
    end

    context 'when status check raises an exception' do
      before do
        # Mock exception during Open3.capture3 (execute_command catches StandardError and returns false)
        allow(Open3).to receive(:capture3)
          .with('orb status')
          .and_raise(StandardError, 'Command failed')
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
      # Mock Open3 to fail (execute_command catches StandardError and returns false tuple)
      allow(Open3).to receive(:capture3).and_raise(StandardError, 'Simulated failure')

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
          .and_return(['/usr/local/bin/orb', '', true])
        allow(cli_class).to receive(:execute_command)
          .with('orb --version')
          .and_return(['orb version 1.0.0', '', true])

        # First check if available
        expect(cli_class.available?).to be(true)

        # Then get version
        expect(cli_class.version).to eq('1.0.0')
      end

      it 'allows checking running status after availability check' do
        # Mock execute_command for sequential calls
        allow(cli_class).to receive(:execute_command)
          .with('which orb')
          .and_return(['/usr/local/bin/orb', '', true])
        allow(cli_class).to receive(:execute_command)
          .with('orb status')
          .and_return(['OrbStack is running', '', true])

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
          .and_return(['', '', false])
      end

      it 'returns consistent false/nil values across all checks' do
        expect(cli_class.available?).to be(false)
        expect(cli_class.version).to be_nil
        expect(cli_class.running?).to be(false)
      end
    end
  end

  # ============================================================================
  # MACHINE LIFECYCLE OPERATION TESTS (SPI-1198)
  # ============================================================================
  #
  # These tests verify the OrbStackCLI utility class methods for managing
  # machine lifecycle operations: listing, querying, creating, deleting,
  # starting, and stopping OrbStack VMs.
  #
  # Reference: SPI-1198 - Enhanced CLI wrapper for machine operations
  # ============================================================================

  describe '.list_machines' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'responds to list_machines class method' do
      expect(cli_class).to respond_to(:list_machines)
    end

    context 'when orb list succeeds with machines' do
      before do
        # Mock successful list command with realistic OrbStack output
        # Format: NAME    STATUS    DISTRO    IP
        machine_list = <<~OUTPUT
          vagrant-test-1    running   ubuntu    192.168.64.10
          vagrant-test-2    stopped   debian    192.168.64.11
        OUTPUT
        allow(cli_class).to receive(:execute_command)
          .with('orb list', timeout: 30)
          .and_return([machine_list, '', true])
      end

      it 'returns array of parsed machine hashes' do
        machines = cli_class.list_machines
        expect(machines).to be_an(Array)
        expect(machines.size).to eq(2)
        expect(machines.first).to include(name: 'vagrant-test-1', status: 'running')
      end
    end

    context 'when orb list returns empty list' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb list', timeout: 30)
          .and_return(['', '', true])
      end

      it 'returns empty array' do
        expect(cli_class.list_machines).to eq([])
      end
    end

    context 'when orb list command fails' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb list', timeout: 30)
          .and_return(['', 'error: command failed', false])
      end

      it 'returns empty array gracefully' do
        expect(cli_class.list_machines).to eq([])
      end
    end

    context 'when orb list times out' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb list', timeout: 30)
          .and_raise(VagrantPlugins::OrbStack::CommandTimeoutError)
      end

      it 'raises CommandTimeoutError' do
        expect { cli_class.list_machines }.to raise_error(VagrantPlugins::OrbStack::CommandTimeoutError)
      end
    end
  end

  describe '.machine_info' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'responds to machine_info class method' do
      expect(cli_class).to respond_to(:machine_info)
    end

    context 'when orb info succeeds with valid JSON' do
      before do
        # Mock successful info command with realistic JSON
        machine_json = {
          name: 'vagrant-test-1',
          status: 'running',
          distro: 'ubuntu',
          ip: '192.168.64.10',
          cpu: 2,
          memory: 4096
        }.to_json
        allow(cli_class).to receive(:execute_command)
          .with('orb info vagrant-test-1', timeout: 30)
          .and_return([machine_json, '', true])
      end

      it 'returns parsed hash from JSON' do
        info = cli_class.machine_info('vagrant-test-1')
        expect(info).to be_a(Hash)
        expect(info['name']).to eq('vagrant-test-1')
        expect(info['status']).to eq('running')
      end
    end

    context 'when machine does not exist' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb info nonexistent', timeout: 30)
          .and_return(['', 'error: machine not found', false])
      end

      it 'returns nil' do
        expect(cli_class.machine_info('nonexistent')).to be_nil
      end
    end

    context 'when orb info returns invalid JSON' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb info invalid-json', timeout: 30)
          .and_return(['not valid json', '', true])
      end

      it 'returns nil gracefully and logs warning' do
        expect(cli_class.machine_info('invalid-json')).to be_nil
      end
    end

    context 'when orb info times out' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb info timeout-test', timeout: 30)
          .and_raise(VagrantPlugins::OrbStack::CommandTimeoutError)
      end

      it 'raises CommandTimeoutError' do
        expect { cli_class.machine_info('timeout-test') }.to raise_error(VagrantPlugins::OrbStack::CommandTimeoutError)
      end
    end
  end

  describe '.create_machine' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'responds to create_machine class method' do
      expect(cli_class).to respond_to(:create_machine)
    end

    context 'when orb create succeeds' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb create ubuntu vagrant-test', timeout: 120)
          .and_return(['Machine created successfully', '', true])
      end

      it 'returns true' do
        expect(cli_class.create_machine('ubuntu', 'vagrant-test')).to be(true)
      end
    end

    context 'when orb create fails' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb create invalid-distro vagrant-test', timeout: 120)
          .and_return(['', 'error: invalid distribution', false])
      end

      it 'raises CommandExecutionError with stderr' do
        expect do
          cli_class.create_machine('invalid-distro', 'vagrant-test')
        end.to raise_error(VagrantPlugins::OrbStack::CommandExecutionError, /invalid distribution/)
      end
    end

    context 'when orb create times out with default timeout' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb create ubuntu slow-machine', timeout: 120)
          .and_raise(VagrantPlugins::OrbStack::CommandTimeoutError)
      end

      it 'raises CommandTimeoutError after 120 seconds' do
        expect do
          cli_class.create_machine('ubuntu', 'slow-machine')
        end.to raise_error(VagrantPlugins::OrbStack::CommandTimeoutError)
      end
    end

    context 'when orb create uses custom timeout' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb create ubuntu custom-timeout', timeout: 300)
          .and_return(['Machine created successfully', '', true])
      end

      it 'respects custom timeout parameter' do
        expect(cli_class.create_machine('ubuntu', 'custom-timeout', timeout: 300)).to be(true)
      end
    end
  end

  describe '.delete_machine' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'responds to delete_machine class method' do
      expect(cli_class).to respond_to(:delete_machine)
    end

    context 'when orb delete succeeds' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb delete vagrant-test', timeout: 60)
          .and_return(['Machine deleted successfully', '', true])
      end

      it 'returns true' do
        expect(cli_class.delete_machine('vagrant-test')).to be(true)
      end
    end

    context 'when orb delete fails' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb delete nonexistent', timeout: 60)
          .and_return(['', 'error: machine not found', false])
      end

      it 'raises CommandExecutionError' do
        expect do
          cli_class.delete_machine('nonexistent')
        end.to raise_error(VagrantPlugins::OrbStack::CommandExecutionError)
      end
    end

    context 'when orb delete times out' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb delete stuck-machine', timeout: 60)
          .and_raise(VagrantPlugins::OrbStack::CommandTimeoutError)
      end

      it 'raises CommandTimeoutError' do
        expect do
          cli_class.delete_machine('stuck-machine')
        end.to raise_error(VagrantPlugins::OrbStack::CommandTimeoutError)
      end
    end
  end

  describe '.start_machine' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'responds to start_machine class method' do
      expect(cli_class).to respond_to(:start_machine)
    end

    context 'when orb start succeeds' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb start vagrant-test', timeout: 60)
          .and_return(['Machine started successfully', '', true])
      end

      it 'returns true' do
        expect(cli_class.start_machine('vagrant-test')).to be(true)
      end
    end

    context 'when orb start fails' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb start broken-machine', timeout: 60)
          .and_return(['', 'error: machine configuration invalid', false])
      end

      it 'raises CommandExecutionError' do
        expect do
          cli_class.start_machine('broken-machine')
        end.to raise_error(VagrantPlugins::OrbStack::CommandExecutionError)
      end
    end

    context 'when orb start times out with default timeout' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb start slow-boot', timeout: 60)
          .and_raise(VagrantPlugins::OrbStack::CommandTimeoutError)
      end

      it 'raises CommandTimeoutError after 60 seconds' do
        expect do
          cli_class.start_machine('slow-boot')
        end.to raise_error(VagrantPlugins::OrbStack::CommandTimeoutError)
      end
    end

    context 'when orb start uses custom timeout' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb start custom-timeout', timeout: 180)
          .and_return(['Machine started successfully', '', true])
      end

      it 'respects custom timeout parameter' do
        expect(cli_class.start_machine('custom-timeout', timeout: 180)).to be(true)
      end
    end
  end

  describe '.stop_machine' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'responds to stop_machine class method' do
      expect(cli_class).to respond_to(:stop_machine)
    end

    context 'when orb stop succeeds' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb stop vagrant-test', timeout: 60)
          .and_return(['Machine stopped successfully', '', true])
      end

      it 'returns true' do
        expect(cli_class.stop_machine('vagrant-test')).to be(true)
      end
    end

    context 'when orb stop fails' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb stop nonexistent', timeout: 60)
          .and_return(['', 'error: machine not found', false])
      end

      it 'raises CommandExecutionError' do
        expect do
          cli_class.stop_machine('nonexistent')
        end.to raise_error(VagrantPlugins::OrbStack::CommandExecutionError)
      end
    end

    context 'when orb stop times out' do
      before do
        allow(cli_class).to receive(:execute_command)
          .with('orb stop stuck-shutdown', timeout: 60)
          .and_raise(VagrantPlugins::OrbStack::CommandTimeoutError)
      end

      it 'raises CommandTimeoutError' do
        expect do
          cli_class.stop_machine('stuck-shutdown')
        end.to raise_error(VagrantPlugins::OrbStack::CommandTimeoutError)
      end
    end
  end

  # ============================================================================
  # ENHANCED EXECUTE_COMMAND TESTS (SPI-1198)
  # ============================================================================

  describe '.execute_command (enhanced)' do
    before do
      require 'vagrant-orbstack/util/orbstack_cli'
    end

    let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

    it 'returns tuple of stdout, stderr, and success boolean' do
      # This test verifies the enhanced signature: [stdout, stderr, success]
      allow(Open3).to receive(:capture3).and_return(['output', 'error', double(success?: true)])

      result = cli_class.send(:execute_command, 'test command')
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
      expect(result[0]).to be_a(String) # stdout
      expect(result[1]).to be_a(String) # stderr
      expect([true, false]).to include(result[2]) # success
    end

    it 'uses Open3.capture3 for command execution' do
      expect(Open3).to receive(:capture3).with('test command').and_return(['out', '', double(success?: true)])
      cli_class.send(:execute_command, 'test command')
    end

    it 'logs at DEBUG level on success' do
      allow(Open3).to receive(:capture3).and_return(['success', '', double(success?: true)])
      logger = cli_class.instance_variable_get(:@logger)
      expect(logger).to receive(:debug).with(/success/)
      cli_class.send(:execute_command, 'successful command')
    end

    it 'logs at ERROR level on failure' do
      allow(Open3).to receive(:capture3).and_return(['', 'failed', double(success?: false)])
      logger = cli_class.instance_variable_get(:@logger)
      expect(logger).to receive(:error).with(/failed/)
      cli_class.send(:execute_command, 'failing command')
    end

    it 'respects timeout parameter using Timeout.timeout' do
      expect(Timeout).to receive(:timeout).with(30).and_call_original
      allow(Open3).to receive(:capture3).and_return(['', '', double(success?: true)])
      cli_class.send(:execute_command, 'timeout test', timeout: 30)
    end

    it 'raises CommandTimeoutError when timeout exceeded' do
      allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      expect do
        cli_class.send(:execute_command, 'slow command', timeout: 1)
      end.to raise_error(VagrantPlugins::OrbStack::CommandTimeoutError)
    end
  end
end
