# frozen_string_literal: true

require 'vagrant-orbstack'

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

      # Error message constants for validation
      DISTRO_EMPTY_ERROR = 'distro cannot be empty'
      MACHINE_NAME_FORMAT_ERROR = 'machine_name must contain only alphanumeric characters and hyphens'

      # Regular expression pattern for valid machine_name format.
      #
      # Valid machine names must:
      # - Start with an alphanumeric character (a-z, A-Z, 0-9)
      # - End with an alphanumeric character
      # - May contain hyphens between alphanumeric segments
      # - No consecutive hyphens allowed
      MACHINE_NAME_PATTERN = /^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$/

      # Initialize configuration with unset values.
      #
      # @api public
      def initialize
        super
        @distro = VagrantPlugins::OrbStack::UNSET_VALUE
        @version = VagrantPlugins::OrbStack::UNSET_VALUE
        @machine_name = VagrantPlugins::OrbStack::UNSET_VALUE
        @logger = Log4r::Logger.new('vagrant_orbstack::config')
      end

      # Finalize configuration by setting defaults.
      #
      # Called by Vagrant after Vagrantfile is loaded to set default values
      # for any unset configuration options.
      #
      # @api public
      def finalize!
        @distro = 'ubuntu' if @distro == VagrantPlugins::OrbStack::UNSET_VALUE
        @version = nil if @version == VagrantPlugins::OrbStack::UNSET_VALUE
        @machine_name = nil if @machine_name == VagrantPlugins::OrbStack::UNSET_VALUE
      end

      # Validate configuration values.
      #
      # @param [Vagrant::Machine] _machine The machine to validate for
      # @return [Hash<String, Array<String>>] Validation errors by namespace
      # @api public
      def validate(_machine)
        errors = _detected_errors
        validate_distro(errors)
        validate_machine_name(errors)
        { 'OrbStack Provider' => errors }
      end

      private

      # Validate that distro attribute is not empty.
      #
      # @param errors [Array<String>] Error accumulator array
      # @return [void]
      def validate_distro(errors)
        return unless @distro.nil? || @distro.strip.empty?

        errors << DISTRO_EMPTY_ERROR
      end

      # Validate machine_name format if set.
      #
      # @param errors [Array<String>] Error accumulator array
      # @return [void]
      def validate_machine_name(errors)
        return unless @machine_name.is_a?(String) && !@machine_name.match?(MACHINE_NAME_PATTERN)

        errors << MACHINE_NAME_FORMAT_ERROR
      end
    end
  end
end
