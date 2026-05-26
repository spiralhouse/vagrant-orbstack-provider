# frozen_string_literal: true

require_relative 'machine_validation'

module VagrantPlugins
  module OrbStack
    module Action
      # Action middleware for opening an interactive SSH console to an OrbStack machine.
      #
      # Validates that the machine exists and is running, then replaces the current
      # process with a native `ssh <machine-name>@orb` session. OrbStack's SSH
      # daemon listens on the `orb` hostname and routes connections by the username,
      # so no custom proxy or port configuration is required.
      #
      # Because the process is replaced via Kernel#exec, control never returns to
      # the middleware chain after a successful connection.
      #
      # @example Usage in action builder
      #   Vagrant::Action::Builder.new.tap do |b|
      #     b.use VagrantPlugins::OrbStack::Action::SSH
      #   end
      #
      # @api public
      class SSH
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
        # Validates that the machine has a valid ID and is in running state, then
        # execs `ssh <machine-id>@orb`, replacing the current process with an
        # interactive SSH session. If the machine is not running, raises an error.
        #
        # @param env [Hash] The environment hash
        # @return [void] Does not return on success (process is replaced by ssh)
        # @raise [ArgumentError] If machine ID is nil or empty (from MachineValidation)
        # @raise [Errors::SSHNotReady] If machine is not in running state
        # @api public
        def call(env)
          machine = env[:machine]

          validate_machine_id!(machine, 'ssh')

          state = machine.provider.state
          raise Errors::SSHNotReady, machine_name: machine.id unless state.id == :running

          exec('ssh', "#{machine.id}@orb")
        end
      end
    end
  end
end
