# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    # Configuration class for OrbStack provider.
    #
    # This class defines configuration options available in Vagrantfiles
    # for customizing OrbStack machine creation and behavior.
    #
    # @example Basic configuration
    #   Vagrant.configure("2") do |config|
    #     config.vm.provider :orbstack do |os|
    #       os.distro = "ubuntu"
    #       os.version = "22.04"
    #       os.machine_name = "my-dev-env"
    #     end
    #   end
    #
    # @api public
    class Config < Vagrant.plugin('2', :config)
      # @!attribute [rw] distro
      #   Linux distribution to use for the machine
      #   @return [String, nil] Distribution name (e.g., "ubuntu", "debian")
      #   @api public
      #
      # @!attribute [rw] version
      #   Distribution version to use
      #   @return [String, nil] Version string (e.g., "22.04")
      #   @api public
      #
      # @!attribute [rw] machine_name
      #   Custom name for the OrbStack machine
      #   @return [String, nil] Machine name
      #   @api public
      attr_accessor :distro
      attr_accessor :version, :machine_name

      # Initialize configuration with unset values.
      #
      # @api public
      def initialize
        super
        @distro = Vagrant::UNSET_VALUE
        @version = Vagrant::UNSET_VALUE
        @machine_name = Vagrant::UNSET_VALUE
      end

      # Finalize configuration by setting defaults.
      #
      # Called by Vagrant after Vagrantfile is loaded to set default values
      # for any unset configuration options.
      #
      # @api public
      def finalize!
        @distro = 'ubuntu' if @distro == Vagrant::UNSET_VALUE
        @version = nil if @version == Vagrant::UNSET_VALUE
        @machine_name = nil if @machine_name == Vagrant::UNSET_VALUE
      end

      # Validate configuration values.
      #
      # @param [Vagrant::Machine] _machine The machine to validate for
      # @return [Hash<String, Array<String>>] Validation errors by namespace
      # @api public
      # @todo Implement configuration validation (tracked in future stories)
      def validate(_machine)
        errors = _detected_errors

        # Validation will be added in future stories
        # For now, return empty errors

        { 'OrbStack Provider' => errors }
      end
    end
  end
end
