# frozen_string_literal: true

require 'open3'
require 'timeout'
require 'json'
require 'vagrant-orbstack/errors'

module VagrantPlugins
  module OrbStack
    module Util
      # Utility class for detecting and interacting with OrbStack CLI
      #
      # This class provides a Ruby interface to the OrbStack command-line tool (`orb`).
      # All methods execute shell commands and return parsed results. The class handles
      # timeouts, error detection, and logging automatically.
      #
      # @example Check if OrbStack is available
      #   if OrbStackCLI.available?
      #     puts "OrbStack version: #{OrbStackCLI.version}"
      #   end
      #
      # @example Create and manage a machine
      #   OrbStackCLI.create_machine('ubuntu', 'my-dev-vm')
      #   OrbStackCLI.start_machine('my-dev-vm')
      #   info = OrbStackCLI.machine_info('my-dev-vm')
      #   OrbStackCLI.stop_machine('my-dev-vm')
      #
      # @example List all machines
      #   machines = OrbStackCLI.list_machines
      #   machines.each do |m|
      #     puts "#{m[:name]} - #{m[:status]}"
      #   end
      class OrbStackCLI
        # Default timeout for non-mutating query operations (list, info).
        # Use this for fast read operations.
        # @return [Integer] Timeout in seconds
        QUERY_TIMEOUT = 30

        # Default timeout for state-changing operations (start, stop, delete).
        # Use this for operations that modify machine state.
        # @return [Integer] Timeout in seconds
        MUTATE_TIMEOUT = 60

        # Default timeout for machine creation operations.
        # Longer timeout accounts for distribution image downloads which
        # can take 30-120 seconds on first use.
        # @return [Integer] Timeout in seconds
        CREATE_TIMEOUT = 120

        @logger = Log4r::Logger.new('vagrant_orbstack::util')

        class << self
          # Check if orb command is available in PATH
          # @return [Boolean] true if orb command exists, false otherwise
          def available?
            stdout, _stderr, success = execute_command('which orb')
            !stdout.empty? && success
          end

          # Get OrbStack version
          # @return [String, nil] version string or nil if not available
          def version
            stdout, _stderr, success = execute_command('orb --version')
            return nil unless success

            # Parse version from output like "orb version 1.2.3" or just "1.2.3"
            match = stdout.match(/(\d+\.\d+\.\d+)/)
            match ? match[1] : nil
          end

          # Check if OrbStack is currently running
          # @return [Boolean] true if running, false otherwise
          def running?
            stdout, _stderr, success = execute_command('orb status')
            success && stdout.match?(/running/i)
          end

          # List all OrbStack machines
          #
          # Executes `orb list` and parses the output into an array of machine hashes.
          # Each hash contains the machine name and current status.
          #
          # @return [Array<Hash>] Array of machine hashes, each with:
          #   - :name [String] The machine name
          #   - :status [String] The machine status (e.g., 'running', 'stopped')
          # @return [Array] Empty array on failure or if no machines exist
          # @raise [CommandTimeoutError] If command times out
          #
          # @example List all machines
          #   machines = OrbStackCLI.list_machines
          #   # => [{name: 'ubuntu-dev', status: 'running'}, {name: 'debian-test', status: 'stopped'}]
          # rubocop:disable Metrics/MethodLength
          def list_machines
            stdout, _stderr, success = execute_command('orb list', timeout: QUERY_TIMEOUT)
            return [] unless success
            return [] if stdout.empty?

            # Parse machine list output (format: NAME STATUS DISTRO IP)
            machines = []
            stdout.each_line do |line|
              parts = line.strip.split(/\s+/)
              next if parts.empty?

              machines << {
                name: parts[0],
                status: parts[1]
              }
            end

            machines
          end
          # rubocop:enable Metrics/MethodLength

          # Get detailed information about a specific machine
          #
          # Executes `orb info <name>` and parses the JSON output. Returns nil if
          # the machine doesn't exist or if JSON parsing fails.
          #
          # @param name [String] The machine name
          # @return [Hash, nil] Parsed machine information hash with OrbStack-specific
          #   fields, or nil if machine not found or parsing fails
          # @raise [CommandTimeoutError] If command times out
          #
          # @example Get machine info
          #   info = OrbStackCLI.machine_info('my-dev-vm')
          #   puts info['distro'] if info
          def machine_info(name)
            stdout, _stderr, success = execute_command("orb info #{name}", timeout: QUERY_TIMEOUT)
            return nil unless success

            JSON.parse(stdout)
          rescue JSON::ParserError => e
            @logger.warn("Failed to parse machine info JSON: #{e.message}")
            nil
          end

          # Create a new OrbStack machine
          #
          # Executes `orb create <distro> <name>`. This operation can take 30-120 seconds
          # on first use if the distribution image needs to be downloaded. Subsequent
          # creations of the same distribution are much faster.
          #
          # @param distro [String] The distribution to use (e.g., 'ubuntu', 'debian')
          # @param name [String] The machine name
          # @param timeout [Integer] Command timeout in seconds (default: CREATE_TIMEOUT)
          # @return [Boolean] true on success
          # @raise [CommandExecutionError] If creation fails
          # @raise [CommandTimeoutError] If command times out
          #
          # @example Create an Ubuntu machine
          #   OrbStackCLI.create_machine('ubuntu', 'my-dev-vm')
          #
          # @example Create with custom timeout for slow networks
          #   OrbStackCLI.create_machine('ubuntu', 'my-vm', timeout: 180)
          # rubocop:disable Naming/PredicateMethod
          def create_machine(distro, name, timeout: CREATE_TIMEOUT)
            _, stderr, success = execute_command("orb create #{distro} #{name}", timeout: timeout)
            raise_unless_successful!('create', stderr, success)
            true
          end

          # Delete an OrbStack machine
          #
          # Executes `orb delete <name>`. This permanently removes the machine and
          # all its data. The operation cannot be undone.
          #
          # @param name [String] The machine name
          # @return [Boolean] true on success
          # @raise [CommandExecutionError] If deletion fails
          # @raise [CommandTimeoutError] If command times out
          #
          # @example Delete a machine
          #   OrbStackCLI.delete_machine('my-dev-vm')
          def delete_machine(name)
            _, stderr, success = execute_command("orb delete #{name}", timeout: MUTATE_TIMEOUT)
            raise_unless_successful!('delete', stderr, success)
            true
          end

          # Start an OrbStack machine
          #
          # Executes `orb start <name>`. Starts a stopped machine. If the machine
          # is already running, this is a no-op.
          #
          # @param name [String] The machine name
          # @param timeout [Integer] Command timeout in seconds (default: MUTATE_TIMEOUT)
          # @return [Boolean] true on success
          # @raise [CommandExecutionError] If start fails
          # @raise [CommandTimeoutError] If command times out
          #
          # @example Start a machine
          #   OrbStackCLI.start_machine('my-dev-vm')
          def start_machine(name, timeout: MUTATE_TIMEOUT)
            _, stderr, success = execute_command("orb start #{name}", timeout: timeout)
            raise_unless_successful!('start', stderr, success)
            true
          end

          # Stop an OrbStack machine
          #
          # Executes `orb stop <name>`. Stops a running machine gracefully. If the
          # machine is already stopped, this is a no-op.
          #
          # @param name [String] The machine name
          # @return [Boolean] true on success
          # @raise [CommandExecutionError] If stop fails
          # @raise [CommandTimeoutError] If command times out
          #
          # @example Stop a machine
          #   OrbStackCLI.stop_machine('my-dev-vm')
          def stop_machine(name)
            _, stderr, success = execute_command("orb stop #{name}", timeout: MUTATE_TIMEOUT)
            raise_unless_successful!('stop', stderr, success)
            true
          end
          # rubocop:enable Naming/PredicateMethod

          private

          # Raises CommandExecutionError unless the operation succeeded
          #
          # Helper method to enforce error handling for mutating operations.
          # Only raises if the operation failed.
          #
          # @param action [String] The action being performed (e.g., 'create', 'delete')
          # @param stderr [String] Error output from CLI
          # @param success [Boolean] Whether the operation succeeded
          # @return [void]
          # @raise [CommandExecutionError] If success is false
          def raise_unless_successful!(action, stderr, success)
            return if success

            raise CommandExecutionError, "Failed to #{action} machine: #{stderr}"
          end

          # Execute an OrbStack CLI command.
          #
          # Executes a shell command using Open3.capture3 and captures stdout,
          # stderr, and exit status. Supports optional timeout for long-running
          # operations. Logs command execution at DEBUG level on success and
          # ERROR level on failure.
          #
          # On any StandardError (other than timeout), returns empty strings and
          # false success flag rather than propagating the exception.
          #
          # @param command [String] The command to execute
          # @param timeout [Integer] Timeout in seconds (default: QUERY_TIMEOUT)
          # @return [Array<String, String, Boolean>] Tuple of [stdout, stderr, success].
          #   All string values are stripped of leading/trailing whitespace.
          # @raise [CommandTimeoutError] If command exceeds timeout
          # @api private
          # rubocop:disable Metrics/MethodLength
          def execute_command(command, timeout: QUERY_TIMEOUT)
            stdout, stderr, status = if timeout
                                       Timeout.timeout(timeout) do
                                         Open3.capture3(command)
                                       end
                                     else
                                       Open3.capture3(command)
                                     end

            success = status.success?

            if success
              @logger.debug("Command succeeded: #{command}")
            else
              @logger.error("Command failed: #{command}, stderr: #{stderr}")
            end

            [stdout.strip, stderr.strip, success]
          rescue Timeout::Error
            @logger.error("Command timed out after #{timeout}s: #{command}")
            raise CommandTimeoutError, "Command timed out: #{command}"
          rescue StandardError => e
            @logger.error("Command error: #{e.message}")
            ['', '', false]
          end
          # rubocop:enable Metrics/MethodLength
        end
      end
    end
  end
end
