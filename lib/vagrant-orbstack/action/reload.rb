# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    module Action
      # Action middleware for reloading (restarting) OrbStack machines.
      #
      # This is a **Composition Action** that orchestrates Halt + Start actions
      # rather than directly interacting with OrbStack CLI. Following the
      # composition pattern, this class:
      #
      # - Does NOT include MachineValidation (composed actions handle validation)
      # - Does NOT directly call OrbStackCLI (delegates to Halt/Start)
      # - Does NOT manage state cache (composed actions handle invalidation)
      #
      # The actual work is performed by the Action::Builder chain in the
      # provider's action method, which composes: Halt → Start → (optional) Provision
      #
      # This class exists as a pattern consistency marker and for potential future
      # pre/post reload logic that doesn't fit in the composed actions.
      #
      # See docs/DESIGN.md "Action Patterns" section for pattern documentation.
      #
      # @example Usage in action builder
      #   Vagrant::Action::Builder.new.tap do |b|
      #     b.use VagrantPlugins::OrbStack::Action::Reload
      #   end
      #
      # @api public
      class Reload
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
        # This is a pass-through middleware - the actual reload logic is
        # composed in the provider's action method. This class exists to
        # maintain consistency with the action middleware pattern.
        #
        # @param env [Hash] The environment hash
        # @return [Object] Result from next middleware
        # @api public
        def call(env)
          # Continue middleware chain
          @app.call(env)
        end
      end
    end
  end
end
