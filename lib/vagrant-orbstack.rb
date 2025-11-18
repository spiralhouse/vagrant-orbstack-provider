# frozen_string_literal: true

require 'pathname'
require 'vagrant-orbstack/plugin'

module VagrantPlugins
  module OrbStack
    lib_path = Pathname.new(File.expand_path('vagrant-orbstack', __dir__))
    autoload :Action, lib_path.join('action')
    autoload :Errors, lib_path.join('errors')

    # This returns the path to the source of this plugin
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('..', __dir__))
    end
  end
end
