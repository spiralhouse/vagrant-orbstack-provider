# frozen_string_literal: true

require_relative 'orbstack_cli'
require_relative '../errors'

module VagrantPlugins
  module OrbStack
    module Util
      # Utility module for waiting until SSH becomes available on an OrbStack machine
      #
      # This module provides a polling mechanism to check if an OrbStack machine
      # is ready for SSH connections. It repeatedly queries the machine status
      # until the machine reports as 'running', indicating SSH is available.
      #
      # @example Wait for SSH on a newly created machine
      #   SSHReadinessChecker.wait_for_ready('my-machine', ui: ui)
      #
      # @example Handle timeout gracefully
      #   begin
      #     SSHReadinessChecker.wait_for_ready('my-machine', ui: ui)
      #   rescue VagrantPlugins::OrbStack::SSHNotReady => e
      #     ui.error("SSH not ready: #{e.message}")
      #   end
      #
      # @api public
      module SSHReadinessChecker
        # Maximum time to wait for SSH to become ready (in seconds)
        # @return [Integer] Timeout in seconds
        MAX_WAIT_TIME = 120

        # Interval between status polls (in seconds)
        # @return [Integer] Poll interval in seconds
        POLL_INTERVAL = 2

        # Wait for SSH to become available on a machine.
        #
        # Polls the machine status every POLL_INTERVAL seconds until the machine
        # reports 'running' status, or until MAX_WAIT_TIME is exceeded. Displays
        # progress messages via the provided UI object.
        #
        # @param machine_name [String] The name of the machine to check
        # @param ui [Vagrant::UI::Interface] UI object for displaying progress messages
        # @return [Boolean] true when SSH is ready
        # @raise [SSHNotReady] If machine doesn't become ready within MAX_WAIT_TIME
        # @raise [CommandExecutionError] If OrbStack CLI command fails
        # @raise [CommandTimeoutError] If OrbStack CLI command times out
        # @raise [OrbStackNotInstalled] If OrbStack CLI is not available
        #
        # @example Wait for SSH
        #   SSHReadinessChecker.wait_for_ready('ubuntu-dev', ui: machine.ui)
        #   # => true
        #
        # @api public
        # rubocop:disable Naming/MethodParameterName
        def self.wait_for_ready(machine_name, ui:)
          # rubocop:enable Naming/MethodParameterName
          ui.info("Waiting for SSH to become available on #{machine_name}...")

          poll_until_ready(machine_name, ui) ||
            raise_timeout_error(machine_name)
        end

        # Poll machine status until ready or timeout.
        #
        # @param machine_name [String] The name of the machine to check
        # @param ui [Vagrant::UI::Interface] UI object for progress messages
        # @return [Boolean, nil] true if ready, nil if timeout
        # @api private
        # rubocop:disable Naming/MethodParameterName, Metrics/MethodLength
        def self.poll_until_ready(machine_name, ui)
          # rubocop:enable Naming/MethodParameterName, Metrics/MethodLength
          start_time = Time.now
          elapsed = 0

          while elapsed < MAX_WAIT_TIME
            if machine_running?(machine_name)
              ui.info('SSH is ready!')
              return true
            end

            sleep(POLL_INTERVAL)
            elapsed = Time.now - start_time
            ui.info("  Still waiting... (#{elapsed.to_i} seconds elapsed)")
          end

          nil
        end

        # Raise timeout error with machine_name parameter for I18n.
        #
        # @param machine_name [String] The name of the machine
        # @raise [SSHNotReady] Always raises with machine_name parameter
        # @api private
        def self.raise_timeout_error(machine_name)
          raise SSHNotReady, machine_name: machine_name
        end

        # Check if machine is in running state.
        #
        # Queries OrbStack CLI for machine status and checks if it's 'running'.
        # Handles nil responses and missing 'status' keys gracefully.
        #
        # @param machine_name [String] The name of the machine to check
        # @return [Boolean] true if machine status is 'running', false otherwise
        # @api private
        def self.machine_running?(machine_name)
          info = OrbStackCLI.machine_info(machine_name)
          info && info.dig('record', 'state') == 'running'
        end

        private_class_method :poll_until_ready, :raise_timeout_error, :machine_running?
      end
    end
  end
end
