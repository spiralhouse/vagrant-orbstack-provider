# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    module Util
      # Utility class for detecting and interacting with OrbStack CLI
      class OrbStackCLI
        class << self
          # Check if orb command is available in PATH
          # @return [Boolean] true if orb command exists, false otherwise
          def available?
            output, success = execute_command('which orb')
            !output.empty? && success
          end

          # Get OrbStack version
          # @return [String, nil] version string or nil if not available
          def version
            output, success = execute_command('orb --version')
            return nil unless success

            # Parse version from output like "orb version 1.2.3" or just "1.2.3"
            match = output.match(/(\d+\.\d+\.\d+)/)
            match ? match[1] : nil
          end

          # Check if OrbStack is currently running
          # @return [Boolean] true if running, false otherwise
          def running?
            output, success = execute_command('orb status')
            success && output.match?(/running/i)
          end

          private

          # Execute an OrbStack CLI command.
          #
          # Executes a shell command and captures output and exit status.
          # Redirects stderr to /dev/null to suppress error messages.
          # Returns empty string and false on any execution error.
          #
          # @param [String] command The command to execute
          # @return [Array<String, Boolean>] Tuple of [output, success]
          # @api private
          def execute_command(command)
            output = `#{command} 2>/dev/null`.strip
            success = $CHILD_STATUS.success?
            [output, success]
          rescue StandardError
            ['', false]
          end
        end
      end
    end
  end
end
