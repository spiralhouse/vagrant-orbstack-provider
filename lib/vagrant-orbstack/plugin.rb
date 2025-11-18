# frozen_string_literal: true

require 'vagrant-orbstack/version'

module VagrantPlugins
  module OrbStack
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-orbstack'
      description 'Enables OrbStack as a Vagrant provider for macOS development'

      # Register provider component
      provider(:orbstack, priority: 5) do
        require_relative 'provider'
        Provider
      end

      # Register config component for provider
      config(:orbstack, :provider) do
        require_relative 'config'
        Config
      end
    end
  end
end
