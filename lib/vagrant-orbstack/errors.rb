# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    # Base error class for OrbStack provider errors.
    # Inherits from Vagrant's VagrantError to integrate with Vagrant's error handling.
    class Errors < Vagrant::Errors::VagrantError
      error_namespace('vagrant_orbstack.errors')
    end

    # Error raised when OrbStack is not installed.
    class OrbStackNotInstalled < Errors
      error_key(:orbstack_not_installed)
    end

    # Error raised when OrbStack is not running.
    class OrbStackNotRunning < Errors
      error_key(:orbstack_not_running)
    end

    # Error raised when an OrbStack CLI command fails.
    class CommandExecutionError < Errors
      error_key(:command_execution_error)
    end

    # Error raised when an OrbStack CLI command times out.
    class CommandTimeoutError < Errors
      error_key(:command_timeout_error)
    end

    # Error raised when machine name collision cannot be resolved after retries.
    class MachineNameCollisionError < Errors
      error_key(:machine_name_collision)
    end

    # Reopen Errors class to add nested constants for namespaced access
    # This allows both VagrantPlugins::OrbStack::CommandTimeoutError
    # and VagrantPlugins::OrbStack::Errors::CommandTimeoutError to work
    class Errors
      # Alias error classes inside Errors namespace for tests that expect them there
      OrbStackNotInstalled = ::VagrantPlugins::OrbStack::OrbStackNotInstalled
      OrbStackNotInstalledError = OrbStackNotInstalled
      OrbStackNotRunning = ::VagrantPlugins::OrbStack::OrbStackNotRunning
      CommandExecutionError = ::VagrantPlugins::OrbStack::CommandExecutionError
      CommandTimeoutError = ::VagrantPlugins::OrbStack::CommandTimeoutError
      MachineNameCollisionError = ::VagrantPlugins::OrbStack::MachineNameCollisionError

      # Alias for CLI errors
      OrbStackCLIError = CommandExecutionError
    end
  end
end
