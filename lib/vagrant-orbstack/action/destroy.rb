# frozen_string_literal: true

require_relative '../util/orbstack_cli'
require_relative 'machine_validation'
require 'fileutils'

module VagrantPlugins
  module OrbStack
    module Action
      # Action middleware for destroying (deleting) OrbStack machines
      #
      # This middleware handles permanent removal of OrbStack machines, including
      # deletion from OrbStack and cleanup of local metadata files. The operation
      # is idempotent and uses a best-effort cleanup strategy: if the OrbStack
      # CLI deletion fails (e.g., machine already deleted or daemon offline), local
      # cleanup continues anyway to ensure Vagrant state remains consistent.
      #
      # @example Usage in action builder
      #   Vagrant::Action::Builder.new.tap do |b|
      #     b.use VagrantPlugins::OrbStack::Action::Destroy
      #   end
      #
      # @api public
      class Destroy
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
        # Destroys the machine by:
        # 1. Calling OrbStack CLI delete command (best-effort)
        # 2. Removing id and metadata.json files from data directory
        # 3. Invalidating state cache
        # 4. Continuing middleware chain
        #
        # If the OrbStack CLI delete fails, a warning is logged and cleanup
        # continues. This ensures Vagrant can clean up its local state even
        # if the machine was already deleted manually or OrbStack is offline.
        #
        # @param env [Hash] The environment hash
        # @return [Object] Result from next middleware
        # @raise [ArgumentError] If machine ID is empty string (nil is handled gracefully)
        # @api public
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def call(env)
          machine = env[:machine]
          ui = env[:ui]

          # Handle already-destroyed machines gracefully (idempotency)
          if machine.id.nil?
            ui.info('Machine is already destroyed or was never created.')
            return @app.call(env)
          end

          # Validate machine ID exists
          machine_id = validate_machine_id!(machine, 'destroy')

          ui.info("Destroying machine '#{machine_id}'...")

          # Call OrbStack CLI to delete the machine (best-effort)
          begin
            Util::OrbStackCLI.delete_machine(machine_id)
          rescue Errors::CommandExecutionError => e
            ui.warn("Error deleting machine from OrbStack: #{e.message}")
            ui.warn('Continuing with local cleanup...')
          end

          # Clean up metadata files from data_dir (idempotent)
          FileUtils.rm_f(machine.provider.id_file_path)
          FileUtils.rm_f(machine.provider.metadata_file_path)

          # Invalidate state cache to ensure fresh state on next query
          machine.provider.invalidate_state_cache

          # Continue middleware chain
          @app.call(env)
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
      end
    end
  end
end
