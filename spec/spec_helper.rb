# frozen_string_literal: true

# RSpec configuration for vagrant-orbstack provider tests
require 'bundler/setup'
require 'pathname'

# Mock Vagrant modules and classes for testing when Vagrant is not available
# This allows tests to run in CI or development without full Vagrant installation
unless defined?(Vagrant)
  module Vagrant
    VERSION = '2.4.0'

    # Sentinel value used to distinguish "not set" from nil
    UNSET_VALUE = Object.new.freeze

    class Logger
      def initialize(*args); end
      def info(*args); end
      def debug(*args); end
      def warn(*args); end
      def error(*args); end
    end

    module Plugin
      class V2
        class Plugin
          class << self
            # Store plugin name (DSL method)
            def name(value = nil)
              if value
                @plugin_name = value
                value
              else
                # Return Ruby class name
                super()
              end
            end

            # Access the DSL-set plugin name
            attr_reader :plugin_name

            def description(value = nil)
              @plugin_description = value if value
              @plugin_description
            end

            def provider(name, _options = {}, &block)
              components.providers[name] = block
            end

            def config(name, scope = nil, &block)
              components.configs[scope] ||= {}
              components.configs[scope][name] = block
            end

            def components
              @components ||= ComponentRegistry.new
            end
          end
        end

        class Provider; end

        class Config
          def _detected_errors
            @_detected_errors ||= []
          end
        end
      end

      class ComponentRegistry
        attr_reader :providers, :configs

        def initialize
          @providers = {}
          @configs = {}
        end
      end
    end

    module Util
      class Subprocess
        def self.execute(*_args)
          # Mock subprocess execution
          double(exit_code: 0, stdout: '', stderr: '')
        end
      end
    end

    class MachineState
      attr_reader :id, :short_description, :long_description

      def initialize(id, short, long)
        @id = id
        @short_description = short
        @long_description = long
      end
    end

    def self.plugin(version, type = nil)
      if version == '2' && type == :provider
        Plugin::V2::Provider
      elsif version == '2' && type == :config
        Plugin::V2::Config
      elsif version == '2'
        Plugin::V2::Plugin
      end
    end

    def self.logger
      @logger ||= Logger.new
    end

    def self.logger=(logger)
      @logger = logger
    end
  end

  # Mock VagrantPlugins module
  module VagrantPlugins
  end
end

# Configure RSpec
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Use expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed

  # Filter out Vagrant's internal warnings
  config.before(:suite) do
    # Suppress Vagrant logging during tests
    Vagrant.logger = Vagrant::Logger.new(nil) if defined?(Vagrant)
  end
end
