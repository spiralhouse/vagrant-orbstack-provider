# frozen_string_literal: true

require_relative '../util/orbstack_cli'
require_relative 'machine_validation'

module VagrantPlugins
  module OrbStack
    module Action
      # Action middleware for halting (stopping) OrbStack machines
      #
      # This middleware handles stopping a running OrbStack machine gracefully.
      # It calls the OrbStack CLI to stop the machine and invalidates the
      # provider's state cache to ensure subsequent state queries are fresh.
      #
      # @example Usage in action builder
      #   Vagrant::Action::Builder.new.tap do |b|
      #     b.use VagrantPlugins::OrbStack::Action::Halt
      #   end
      #
      # @api public
      class Halt
        include MachineValidation

        # Initialize the middleware.
        #
        # @param app [Object] The next middleware in the chain
        # @param env [Hash] The environment hash containing :machine, :ui, etc.
        # @api public
        def initialize(app, env)
          @app = app
          @env = env
        end

        # Execute the middleware.
        #
        # Halts the machine by calling OrbStack CLI stop command,
        # then invalidates the state cache to ensure fresh state queries.
        #
        # @param env [Hash] The environment hash
        # @return [Object] Result from next middleware
        # @raise [CommandExecutionError] If stop command fails
        # @raise [CommandTimeoutError] If stop command times out
        # @api public
        def call(env)
          machine = env[:machine]
          ui = env[:ui]

          # Validate machine ID exists
          machine_id = validate_machine_id!(machine, 'halt')

          ui.info("Halting machine '#{machine_id}'...")

          # Call OrbStack CLI to stop the machine
          Util::OrbStackCLI.stop_machine(machine_id)

          # Invalidate state cache to ensure fresh state on next query
          machine.provider.invalidate_state_cache

          # Continue middleware chain
          @app.call(env)
        end
      end
    end
  end
end
