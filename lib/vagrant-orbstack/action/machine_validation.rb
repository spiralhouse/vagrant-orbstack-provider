# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    module Action
      # Machine validation mixin for action middleware.
      #
      # This module provides machine ID validation for **Direct Action Pattern**
      # actions that interact directly with OrbStack CLI. Include this module
      # when your action needs to validate machine existence before performing
      # CLI operations.
      #
      # **IMPORTANT**: Do NOT include this module in Composition Actions that
      # orchestrate other actions. Composition actions delegate validation to
      # their composed actions to avoid redundant checks.
      #
      # ## Usage
      #
      # ### Direct Actions (Include this module)
      # - Create, Halt, Start, Destroy
      # - Any action that directly calls Util::OrbStackCLI
      # - Actions that manage state cache directly
      #
      # ### Composition Actions (Do NOT include)
      # - Reload (composes Halt + Start, which both validate)
      # - Any action that only orchestrates via Action::Builder
      #
      # See docs/DESIGN.md "Action Patterns" for complete pattern documentation.
      #
      # @example Include in a direct action
      #   class Destroy
      #     include MachineValidation
      #
      #     def call(env)
      #       machine_id = validate_machine_id!(env[:machine], 'destroy')
      #       # ...
      #     end
      #   end
      #
      # @api public
      module MachineValidation
        # Validate that a machine has a non-nil, non-empty ID.
        #
        # @param machine [Vagrant::Machine] The machine to validate
        # @param action_name [String] The action being performed (for error messages)
        # @return [String] The machine ID if valid
        # @raise [ArgumentError] If machine ID is nil or empty
        # @api public
        def validate_machine_id!(machine, action_name)
          machine_id = machine.id
          if machine_id.nil? || machine_id.empty?
            raise ArgumentError,
                  "Cannot #{action_name} machine: machine ID is nil or empty"
          end
          machine_id
        end
      end
    end
  end
end
