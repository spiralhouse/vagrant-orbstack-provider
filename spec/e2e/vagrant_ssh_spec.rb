# frozen_string_literal: true

# End-to-end SSH connectivity tests
#
# This test suite validates REAL SSH connectivity with actual OrbStack machines.
# Tests execute actual vagrant ssh commands against real OrbStack VMs to verify
# the complete SSH integration stack.
#
# REQUIREMENTS:
# - OrbStack must be installed and running
# - Tests are automatically skipped if OrbStack is not available
# - Tests create and destroy real OrbStack machines
# - Each test cleans up after itself
#
# Expected behavior:
# - vagrant ssh opens interactive shell when machine is running
# - vagrant ssh -c "command" executes single command and returns output
# - SSH connection establishes within expected timeframe
# - SSH works after halt/up cycle
# - Provisioners can execute commands over SSH

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'Vagrant SSH E2E Tests', :e2e do
  # ============================================================================
  # HELPER METHODS
  # ============================================================================

  # Check if OrbStack is installed and running
  #
  # @return [Boolean] true if OrbStack is available
  def orbstack_available?
    system('which orb > /dev/null 2>&1') &&
      system('orb status > /dev/null 2>&1')
  end

  # Create a temporary Vagrantfile for testing
  #
  # @param dir [String] Directory to create Vagrantfile in
  # @param machine_name [String] Name of the machine (default: 'default')
  # @param distro [String] Distribution to use (default: 'ubuntu')
  # @param version [String] Distribution version (default: 'noble')
  # @return [void]
  def create_vagrantfile(dir, machine_name: 'default', distro: 'ubuntu', version: 'noble')
    vagrantfile_content = <<~VAGRANTFILE
      Vagrant.configure("2") do |config|
        config.vm.box = "orbstack"

        config.vm.provider :orbstack do |os|
          os.distro = "#{distro}"
          os.version = "#{version}"
        end
      end
    VAGRANTFILE

    File.write(File.join(dir, 'Vagrantfile'), vagrantfile_content)
  end

  # Execute vagrant command in specified directory
  #
  # @param dir [String] Directory containing Vagrantfile
  # @param command [String] Vagrant command to execute (e.g., 'up', 'ssh -c "echo hello"')
  # @param timeout [Integer] Command timeout in seconds (default: 180)
  # @return [Hash] Hash with :success, :stdout, :stderr, :exit_code
  def vagrant_exec(dir, command, timeout: 180)
    stdout_str = ''
    stderr_str = ''
    exit_code = nil

    # Use Bundler.with_unbundled_env to prevent gem conflicts
    Bundler.with_unbundled_env do
      Dir.chdir(dir) do
        require 'open3'
        require 'timeout'

        begin
          Timeout.timeout(timeout) do
            Open3.popen3("vagrant #{command}") do |_stdin, stdout, stderr, wait_thr|
              stdout_str = stdout.read
              stderr_str = stderr.read
              exit_code = wait_thr.value.exitstatus
            end
          end
        rescue Timeout::Error
          return {
            success: false,
            stdout: stdout_str,
            stderr: "Command timed out after #{timeout} seconds",
            exit_code: 124 # Standard timeout exit code
          }
        end
      end
    end

    {
      success: exit_code.zero?,
      stdout: stdout_str,
      stderr: stderr_str,
      exit_code: exit_code
    }
  end

  # Clean up Vagrant machine
  #
  # @param dir [String] Directory containing Vagrantfile
  # @return [void]
  def cleanup_vagrant_machine(dir)
    vagrant_exec(dir, 'destroy -f', timeout: 60)
  rescue StandardError => e
    warn "Failed to clean up Vagrant machine: #{e.message}"
  end

  # ============================================================================
  # E2E SSH TESTS
  # ============================================================================

  before(:each) do
    skip 'OrbStack not installed or not running' unless orbstack_available?
  end

  describe 'vagrant ssh command execution' do
    let(:test_dir) { Dir.mktmpdir('vagrant-ssh-e2e-test') }

    before do
      create_vagrantfile(test_dir)
    end

    after do
      cleanup_vagrant_machine(test_dir)
      FileUtils.rm_rf(test_dir)
    end

    it 'executes simple echo command via vagrant ssh -c' do
      # Arrange - create and start machine
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true, "vagrant up failed: #{up_result[:stderr]}"

      # Act - execute SSH command
      result = vagrant_exec(test_dir, 'ssh -c "echo hello"', timeout: 30)

      # Assert
      expect(result[:success]).to be true
      expect(result[:stdout]).to include('hello')
    end

    it 'returns correct output from whoami command' do
      # Arrange - create and start machine
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true, "vagrant up failed: #{up_result[:stderr]}"

      # Get machine ID from vagrant status
      status_result = vagrant_exec(test_dir, 'status', timeout: 30)
      expect(status_result[:success]).to be true

      # Act - execute whoami command
      result = vagrant_exec(test_dir, 'ssh -c "whoami"', timeout: 30)

      # Assert - whoami should return the machine ID (username for OrbStack SSH proxy)
      expect(result[:success]).to be true
      # Extract machine ID from status output (format: "default running (orbstack)")
      # Machine ID is username for SSH proxy routing
      expect(result[:stdout].strip).to match(/^vagrant-default-[a-f0-9]{6}$/)
    end

    it 'executes multiple commands in sequence' do
      # Arrange - create and start machine
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true, "vagrant up failed: #{up_result[:stderr]}"

      # Act - execute multiple SSH commands
      result1 = vagrant_exec(test_dir, 'ssh -c "echo first"', timeout: 30)
      result2 = vagrant_exec(test_dir, 'ssh -c "echo second"', timeout: 30)
      result3 = vagrant_exec(test_dir, 'ssh -c "echo third"', timeout: 30)

      # Assert
      expect(result1[:success]).to be true
      expect(result1[:stdout]).to include('first')

      expect(result2[:success]).to be true
      expect(result2[:stdout]).to include('second')

      expect(result3[:success]).to be true
      expect(result3[:stdout]).to include('third')
    end

    it 'can create and read files via SSH' do
      # Arrange - create and start machine
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true, "vagrant up failed: #{up_result[:stderr]}"

      # Act - create file and read it back
      write_result = vagrant_exec(test_dir, 'ssh -c "echo test-content > /tmp/test-file.txt"', timeout: 30)
      expect(write_result[:success]).to be true

      read_result = vagrant_exec(test_dir, 'ssh -c "cat /tmp/test-file.txt"', timeout: 30)

      # Assert
      expect(read_result[:success]).to be true
      expect(read_result[:stdout]).to include('test-content')
    end
  end

  describe 'SSH connectivity after halt/up cycle' do
    let(:test_dir) { Dir.mktmpdir('vagrant-ssh-halt-test') }

    before do
      create_vagrantfile(test_dir)
    end

    after do
      cleanup_vagrant_machine(test_dir)
      FileUtils.rm_rf(test_dir)
    end

    it 'SSH works after vagrant halt and vagrant up' do
      # Arrange - create and start machine
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true, "vagrant up failed: #{up_result[:stderr]}"

      # Verify initial SSH works
      ssh_result1 = vagrant_exec(test_dir, 'ssh -c "echo before-halt"', timeout: 30)
      expect(ssh_result1[:success]).to be true
      expect(ssh_result1[:stdout]).to include('before-halt')

      # Act - halt and restart machine
      halt_result = vagrant_exec(test_dir, 'halt', timeout: 60)
      expect(halt_result[:success]).to be true, "vagrant halt failed: #{halt_result[:stderr]}"

      up_result2 = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result2[:success]).to be true, "vagrant up after halt failed: #{up_result2[:stderr]}"

      # Assert - SSH should work after restart
      ssh_result2 = vagrant_exec(test_dir, 'ssh -c "echo after-up"', timeout: 30)
      expect(ssh_result2[:success]).to be true
      expect(ssh_result2[:stdout]).to include('after-up')
    end

    it 'machine state persists across halt/up cycle' do
      # Arrange - create machine and create a file
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true

      write_result = vagrant_exec(test_dir, 'ssh -c "echo persistent-data > /tmp/persistent.txt"', timeout: 30)
      expect(write_result[:success]).to be true

      # Act - halt and restart
      halt_result = vagrant_exec(test_dir, 'halt', timeout: 60)
      expect(halt_result[:success]).to be true

      up_result2 = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result2[:success]).to be true

      # Assert - file should still exist
      read_result = vagrant_exec(test_dir, 'ssh -c "cat /tmp/persistent.txt"', timeout: 30)
      expect(read_result[:success]).to be true
      expect(read_result[:stdout]).to include('persistent-data')
    end
  end

  describe 'SSH connectivity timing' do
    let(:test_dir) { Dir.mktmpdir('vagrant-ssh-timing-test') }

    before do
      create_vagrantfile(test_dir)
    end

    after do
      cleanup_vagrant_machine(test_dir)
      FileUtils.rm_rf(test_dir)
    end

    it 'SSH connection establishes within 5 seconds of machine being ready' do
      # Arrange - create and start machine
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true

      # Act - measure time for SSH connection
      start_time = Time.now
      ssh_result = vagrant_exec(test_dir, 'ssh -c "echo ready"', timeout: 30)
      ssh_time = Time.now - start_time

      # Assert
      expect(ssh_result[:success]).to be true
      expect(ssh_result[:stdout]).to include('ready')
      expect(ssh_time).to be < 5.0, "SSH took #{ssh_time}s, expected < 5s"
    end
  end

  describe 'provisioner SSH execution' do
    let(:test_dir) { Dir.mktmpdir('vagrant-ssh-provisioner-test') }

    before do
      # Create Vagrantfile with shell provisioner
      vagrantfile_content = <<~VAGRANTFILE
        Vagrant.configure("2") do |config|
          config.vm.box = "orbstack"

          config.vm.provider :orbstack do |os|
            os.distro = "ubuntu"
            os.version = "noble"
          end

          # Shell provisioner to test SSH execution
          config.vm.provision "shell", inline: <<-SHELL
            echo "Provisioner executed successfully" > /tmp/provisioner-result.txt
          SHELL
        end
      VAGRANTFILE

      File.write(File.join(test_dir, 'Vagrantfile'), vagrantfile_content)
    end

    after do
      cleanup_vagrant_machine(test_dir)
      FileUtils.rm_rf(test_dir)
    end

    it 'shell provisioner executes commands over SSH successfully' do
      # Arrange & Act - vagrant up runs provisioner automatically
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)

      # Assert - vagrant up should succeed
      expect(up_result[:success]).to be true, "vagrant up failed: #{up_result[:stderr]}"

      # Verify provisioner executed
      read_result = vagrant_exec(test_dir, 'ssh -c "cat /tmp/provisioner-result.txt"', timeout: 30)
      expect(read_result[:success]).to be true
      expect(read_result[:stdout]).to include('Provisioner executed successfully')
    end

    it 'vagrant reload --provision re-runs provisioner over SSH' do
      # Arrange - initial up
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true

      # Remove provisioner result file
      vagrant_exec(test_dir, 'ssh -c "rm -f /tmp/provisioner-result.txt"', timeout: 30)

      # Act - reload with provisioning
      reload_result = vagrant_exec(test_dir, 'reload --provision', timeout: 300)
      expect(reload_result[:success]).to be true

      # Assert - provisioner should have re-created the file
      read_result = vagrant_exec(test_dir, 'ssh -c "cat /tmp/provisioner-result.txt"', timeout: 30)
      expect(read_result[:success]).to be true
      expect(read_result[:stdout]).to include('Provisioner executed successfully')
    end
  end

  describe 'SSH connection stability' do
    let(:test_dir) { Dir.mktmpdir('vagrant-ssh-stability-test') }

    before do
      create_vagrantfile(test_dir)
    end

    after do
      cleanup_vagrant_machine(test_dir)
      FileUtils.rm_rf(test_dir)
    end

    it 'SSH connection does not drop during long-running command' do
      # Arrange - create and start machine
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true

      # Act - execute command that takes several seconds
      result = vagrant_exec(test_dir, 'ssh -c "for i in 1 2 3 4 5; do echo iteration-$i; sleep 1; done"', timeout: 30)

      # Assert - should complete all iterations without dropping
      expect(result[:success]).to be true
      expect(result[:stdout]).to include('iteration-1')
      expect(result[:stdout]).to include('iteration-2')
      expect(result[:stdout]).to include('iteration-3')
      expect(result[:stdout]).to include('iteration-4')
      expect(result[:stdout]).to include('iteration-5')
    end

    it 'handles multiple concurrent SSH connections' do
      # Arrange - create and start machine
      up_result = vagrant_exec(test_dir, 'up --provider=orbstack', timeout: 300)
      expect(up_result[:success]).to be true

      # Act - execute multiple SSH commands concurrently
      threads = 5.times.map do |i|
        Thread.new do
          vagrant_exec(test_dir, "ssh -c 'echo thread-#{i}'", timeout: 30)
        end
      end

      results = threads.map(&:value)

      # Assert - all connections should succeed
      expect(results.all? { |r| r[:success] }).to be true
      results.each_with_index do |result, i|
        expect(result[:stdout]).to include("thread-#{i}")
      end
    end
  end
end
