# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    # Base error class for OrbStack provider errors.
    # Inherits from Vagrant's VagrantError to integrate with Vagrant's error handling.
    class Errors < Vagrant::Errors::VagrantError
      error_namespace("vagrant_orbstack.errors")
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
  end
end
