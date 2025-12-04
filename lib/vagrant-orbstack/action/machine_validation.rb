# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    module Action
      # Shared validation logic for action middleware.
      #
      # This module provides common validation methods that can be included
      # in action middleware classes to ensure consistent validation behavior.
      #
      # @example Include in an action
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
