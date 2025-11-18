# frozen_string_literal: true

require 'pathname'
require 'vagrant-orbstack/plugin'

module VagrantPlugins
  # OrbStack provider for Vagrant.
  #
  # This module contains the implementation of the OrbStack provider plugin,
  # enabling Vagrant to use OrbStack as a backend for managing Linux
  # development environments on macOS.
  #
  # @see Plugin
  # @see Provider
  # @see Config
  module OrbStack
    lib_path = Pathname.new(File.join(__dir__, 'vagrant-orbstack'))
    autoload :Action, lib_path.join('action')
    autoload :Errors, lib_path.join('errors')

    # Returns the path to the source of this plugin.
    #
    # @return [Pathname] Root directory of the plugin source
    # @api private
    def self.source_root
      @source_root ||= Pathname.new(File.join(__dir__, '..'))
    end
  end
end
