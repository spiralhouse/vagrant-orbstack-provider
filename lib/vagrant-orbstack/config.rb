# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    class Config < Vagrant.plugin('2', :config)
      # Configuration attributes
      attr_accessor :distro
      attr_accessor :version, :machine_name

      def initialize
        super
        @distro = Vagrant::UNSET_VALUE
        @version = Vagrant::UNSET_VALUE
        @machine_name = Vagrant::UNSET_VALUE
      end

      # Finalize configuration (set defaults)
      def finalize!
        @distro = 'ubuntu' if @distro == Vagrant::UNSET_VALUE
        @version = nil if @version == Vagrant::UNSET_VALUE
        @machine_name = nil if @machine_name == Vagrant::UNSET_VALUE
      end

      # Validate configuration
      def validate(_machine)
        errors = _detected_errors

        # Validation will be added in future stories
        # For now, return empty errors

        { 'OrbStack Provider' => errors }
      end
    end
  end
end
