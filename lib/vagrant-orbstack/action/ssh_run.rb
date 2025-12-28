# frozen_string_literal: true

require_relative 'machine_validation'

module VagrantPlugins
  module OrbStack
    module Action
      # Action middleware for validating SSH readiness before command execution
      #
      # This middleware validates that the machine is in a running state before
      # Vagrant executes SSH commands via `vagrant ssh -c "command"`. It does NOT
      # execute the SSH command itself - Vagrant's built-in SSH layer handles that
      # after this validation middleware approves the operation.
      #
      # Unlike other actions, SSHRun is read-only: it only validates state and does
      # not call OrbStack CLI or modify machine state. This makes it safe to call
      # repeatedly without side effects.
      #
      # @example Usage in action builder
      #   Vagrant::Action::Builder.new.tap do |b|
      #     b.use VagrantPlugins::OrbStack::Action::SSHRun
      #   end
      #
      # @api public
      class SSHRun
        include MachineValidation

        # Initialize the middleware.
        #
        # @param app [Object] The next middleware in the chain
        # @param env [Hash] The environment hash containing :machine, :ui, etc.
        # @api public
        def initialize(app, _env)
          @app = app
        end

        # Execute the middleware.
        #
        # Validates that the machine has a valid ID and is in running state.
        # If validation passes, continues the middleware chain for Vagrant to
        # execute the SSH command. If validation fails, raises an error and
        # blocks SSH command execution.
        #
        # This is a read-only operation:
        # - Does NOT call OrbStack CLI (only queries cached state)
        # - Does NOT invalidate state cache (no state changes occur)
        # - Does NOT display UI messages (validation only)
        #
        # @param env [Hash] The environment hash
        # @return [Object] Result from next middleware
        # @raise [ArgumentError] If machine ID is nil or empty (from MachineValidation)
        # @raise [Errors::SSHNotReady] If machine is not in running state
        # @api public
        def call(env)
          machine = env[:machine]

          # Validate machine ID exists (from MachineValidation)
          validate_machine_id!(machine, 'ssh')

          # Validate machine is running
          state = machine.provider.state
          raise Errors::SSHNotReady, machine_name: machine.id unless state.id == :running

          # Continue middleware chain (Vagrant handles SSH execution)
          @app.call(env)
        end
      end
    end
  end
end
