# frozen_string_literal: true

require 'time'
require_relative '../util/machine_namer'
require_relative '../util/orbstack_cli'

module VagrantPlugins
  module OrbStack
    module Action
      # Action middleware for creating and starting OrbStack machines
      #
      # This middleware handles the machine creation lifecycle with full
      # idempotency support. It checks the current machine state and:
      # - If running: does nothing (no-op)
      # - If stopped: starts the existing machine
      # - If not created: creates a new machine with unique name
      #
      # After creation, persists machine metadata and invalidates state cache.
      #
      # @example Usage in action builder
      #   Vagrant::Action::Builder.new.tap do |b|
      #     b.use VagrantPlugins::OrbStack::Action::Create
      #   end
      #
      # @api public
      class Create
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
        # Implements idempotent machine creation:
        # 1. Query current state
        # 2. If running: no-op
        # 3. If stopped: start machine
        # 4. If not created: create new machine
        # 5. Persist metadata and invalidate cache
        # 6. Continue middleware chain
        #
        # @param env [Hash] The environment hash
        # @return [Object] Result from next middleware
        # @raise [MachineNameCollisionError] If name generation fails
        # @raise [OrbStackNotInstalled] If OrbStack CLI not available
        # @raise [CommandTimeoutError] If CLI command times out
        # @raise [CommandExecutionError] If machine creation/start fails
        # @api public
        def call(env)
          handle_machine_state(env)
          @app.call(env)
        end

        private

        # Route to appropriate state handler based on current machine state.
        #
        # @param env [Hash] The environment hash
        # @return [void]
        # @api private
        def handle_machine_state(env)
          current_state = env[:machine].provider.state

          case current_state.id
          when :running  then handle_running_machine(env)
          when :stopped  then handle_stopped_machine(env)
          else                handle_not_created_machine(env)
          end
        end

        # Handle a machine that is already running (no-op).
        #
        # @param env [Hash] The environment hash
        # @return [void]
        # @api private
        def handle_running_machine(env)
          env[:machine].ui.info('Machine is already running')
        end

        # Handle a machine that is stopped by starting it.
        #
        # @param env [Hash] The environment hash
        # @return [void]
        # @api private
        def handle_stopped_machine(env)
          machine = env[:machine]
          machine.ui.info('Starting stopped machine...')
          Util::OrbStackCLI.start_machine(machine.id)
          machine.provider.invalidate_state_cache
        end

        # Handle a machine that doesn't exist by creating it.
        #
        # @param env [Hash] The environment hash
        # @return [void]
        # @api private
        def handle_not_created_machine(env)
          create_machine(env)
        end

        # Create a new OrbStack machine.
        #
        # Generates unique machine name, creates machine via OrbStack CLI,
        # persists metadata, and invalidates state cache.
        #
        # @param env [Hash] The environment hash
        # @return [void]
        # @api private
        def create_machine(env)
          machine = env[:machine]
          ui = machine.ui

          ui.info('Creating new machine...')

          machine_name = Util::MachineNamer.generate(machine)
          distro = build_distribution_string(machine.provider_config)
          Util::OrbStackCLI.create_machine(machine_name, distribution: distro)

          persist_metadata(env, machine_name, distro)

          ui.info("Machine '#{machine_name}' created successfully")
        end

        # Build distribution string from configuration.
        #
        # Formats the distribution string for OrbStack CLI based on
        # configured distro and version. If version is specified, returns
        # "distro:version", otherwise just "distro".
        #
        # @param config [VagrantPlugins::OrbStack::Config] Provider configuration
        # @return [String] Formatted distribution string
        # @api private
        def build_distribution_string(config)
          return config.distro unless config.version
          "#{config.distro}:#{config.version}"
        end

        # Persist machine metadata to Vagrant data directory.
        #
        # Stores machine ID and metadata (name, distribution, timestamp)
        # for future Vagrant operations.
        #
        # @param env [Hash] The environment hash
        # @param machine_name [String] The generated machine name
        # @param distro [String] The distribution string (e.g., "ubuntu:noble")
        # @return [void]
        # @api private
        def persist_metadata(env, machine_name, distro)
          machine = env[:machine]
          provider = machine.provider

          # Store machine ID (Vagrant core will call machine.id= after this)
          provider.write_machine_id(machine_name)

          # Store metadata
          metadata = {
            'machine_name' => machine_name,
            'distribution' => distro,
            'created_at' => Time.now.utc.iso8601
          }
          provider.write_metadata(metadata)

          # Invalidate state cache to force fresh query
          provider.invalidate_state_cache
        end
      end
    end
  end
end
