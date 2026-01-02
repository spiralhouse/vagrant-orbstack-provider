# frozen_string_literal: true

require 'vagrant-orbstack/version'

module VagrantPlugins
  # OrbStack provider plugin namespace
  module OrbStack
    # OrbStack provider plugin for Vagrant.
    #
    # This plugin enables OrbStack as a provider backend for Vagrant,
    # allowing users to create and manage Linux development environments
    # on macOS using OrbStack's high-performance virtualization.
    #
    # @api public
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-orbstack'
      description 'Enables OrbStack as a Vagrant provider for macOS development'

      # Register OrbStack provider with Vagrant.
      #
      # @api private
      provider(:orbstack, priority: 5) do
        require_relative 'provider'
        Provider
      end

      # Register configuration class for OrbStack provider.
      #
      # @api private
      config(:orbstack, :provider) do
        require_relative 'config'
        Config
      end

      # Setup I18n locale files for error messages
      def self.setup!
        locale_path = Pathname.new(File.expand_path('../locales', __dir__))
        I18n.load_path << locale_path.join('en.yml') if locale_path.exist?
      end
    end

    # Initialize I18n on plugin load
    Plugin.setup!
  end
end
