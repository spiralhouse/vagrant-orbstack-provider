# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    class Provider < Vagrant.plugin('2', :provider)
      def initialize(machine)
        @machine = machine
      end

      # Return action middleware for requested operation
      def action(_name)
        # Stub for now - will be implemented in future stories
        nil
      end

      # Provide SSH connection information
      def ssh_info
        # Stub for now - will be implemented in future stories
        nil
      end

      # Return current machine state
      def state
        # Stub for now - will be implemented in future stories
        Vagrant::MachineState.new(:not_created, 'not created', 'Machine does not exist')
      end

      # Human-readable provider description
      def to_s
        'OrbStack'
      end
    end
  end
end
