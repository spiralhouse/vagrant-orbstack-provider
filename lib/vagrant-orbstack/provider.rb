# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    # Vagrant provider implementation for OrbStack.
    #
    # This class implements the Vagrant provider interface, delegating
    # machine lifecycle operations to OrbStack via CLI commands.
    #
    # @api public
    class Provider < Vagrant.plugin('2', :provider)
      # Initialize the provider with a machine instance.
      #
      # @param [Vagrant::Machine] machine The machine this provider is for
      # @api public
      def initialize(machine)
        @machine = machine
      end

      # Return action middleware for requested operation.
      #
      # @param [Symbol] _name The action name
      # @return [Object, nil] Action middleware (currently stubbed)
      # @api public
      # @todo Implement action middleware (tracked in future stories)
      def action(_name)
        # Stub for now - will be implemented in future stories
        nil
      end

      # Provide SSH connection information for the machine.
      #
      # @return [Hash, nil] SSH connection parameters (currently stubbed)
      # @api public
      # @todo Implement SSH info retrieval (tracked in future stories)
      def ssh_info
        # Stub for now - will be implemented in future stories
        nil
      end

      # Return current machine state.
      #
      # @return [Vagrant::MachineState] Current state of the machine
      # @api public
      # @todo Implement actual state detection (tracked in future stories)
      def state
        # Stub for now - will be implemented in future stories
        Vagrant::MachineState.new(:not_created, 'not created', 'Machine does not exist')
      end

      # Human-readable provider description.
      #
      # @return [String] Provider name
      # @api public
      def to_s
        'OrbStack'
      end
    end
  end
end
