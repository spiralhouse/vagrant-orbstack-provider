# frozen_string_literal: true

require_relative '../util/orbstack_cli'

module VagrantPlugins
  module OrbStack
    module Action
      # Action middleware for starting OrbStack machines
      #
      # This middleware handles starting a stopped OrbStack machine.
      # It calls the OrbStack CLI to start the machine and invalidates the
      # provider's state cache to ensure subsequent state queries are fresh.
      #
      # The OrbStack CLI is idempotent - starting an already running machine
      # is safe and will not cause an error.
      #
      # @example Usage in action builder
      #   Vagrant::Action::Builder.new.tap do |b|
      #     b.use VagrantPlugins::OrbStack::Action::Start
      #   end
      #
      # @api public
      class Start
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
        # Starts the machine by calling OrbStack CLI start command,
        # then invalidates the state cache to ensure fresh state queries.
        #
        # @param env [Hash] The environment hash
        # @return [Object] Result from next middleware
        # @raise [CommandExecutionError] If start command fails
        # @raise [CommandTimeoutError] If start command times out
        # @raise [OrbStackNotInstalledError] If OrbStack CLI is not available
        # @api public
        # rubocop:disable Metrics/MethodLength
        def call(env)
          machine = env[:machine]
          ui = env[:ui]

          # Validate machine ID exists
          machine_id = machine.id
          if machine_id.nil? || machine_id.empty?
            raise ArgumentError,
                  'Cannot start machine: machine ID is nil or empty'
          end

          ui.info("Starting machine '#{machine_id}'...")

          # Call OrbStack CLI to start the machine
          Util::OrbStackCLI.start_machine(machine_id)

          # Invalidate state cache to ensure fresh state on next query
          machine.provider.invalidate_state_cache

          # Continue middleware chain
          @app.call(env)
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
