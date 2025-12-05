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
      #
      # @!attribute [rw] ssh_username
      #   Custom SSH username for connecting to the machine
      #   @return [String, nil] SSH username (defaults to OrbStack's default if nil)
      #   @api public
      attr_accessor :distro
      attr_accessor :version, :machine_name, :ssh_username

      # Error message constants for validation
      DISTRO_EMPTY_ERROR = 'distro cannot be empty'
      MACHINE_NAME_FORMAT_ERROR = 'machine_name must contain only alphanumeric characters and hyphens'
      SSH_USERNAME_EMPTY_ERROR = 'ssh_username cannot be empty'

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
        @ssh_username = VagrantPlugins::OrbStack::UNSET_VALUE
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
        @ssh_username = nil if @ssh_username == VagrantPlugins::OrbStack::UNSET_VALUE
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
        validate_ssh_username(errors)
        { 'OrbStack Provider' => errors }
      end

      private

      # Validation methods use defensive type coercion (.to_s) to prevent
      # NoMethodError crashes if attributes are accidentally set to non-String types.
      # This approach prioritizes robustness over strict type enforcement.
      #
      # Pattern: Always check nil first, then coerce to string for validation.
      #
      # Example:
      #   return if @attribute.nil?
      #   errors << ERROR_CONSTANT if @attribute.to_s.strip.empty?

      # Validate that distro attribute is not empty.
      #
      # @param errors [Array<String>] Error accumulator array
      # @return [void]
      def validate_distro(errors)
        errors << DISTRO_EMPTY_ERROR if @distro.nil? || @distro.to_s.strip.empty?
      end

      # Validate machine_name format if set.
      #
      # @param errors [Array<String>] Error accumulator array
      # @return [void]
      def validate_machine_name(errors)
        return if @machine_name.nil?

        # Convert to string for regex matching (defensive programming)
        machine_name_str = @machine_name.to_s
        errors << MACHINE_NAME_FORMAT_ERROR unless machine_name_str.match?(MACHINE_NAME_PATTERN)
      end

      # Validate that ssh_username attribute is not empty if set.
      #
      # @param errors [Array<String>] Error accumulator array
      # @return [void]
      def validate_ssh_username(errors)
        return if @ssh_username.nil?
        return unless @ssh_username.to_s.strip.empty?

        errors << SSH_USERNAME_EMPTY_ERROR
      end
    end
  end
end
