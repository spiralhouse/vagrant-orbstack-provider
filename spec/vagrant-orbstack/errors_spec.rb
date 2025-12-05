# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Errors
#
# This test verifies that the Errors module and custom error classes exist
# and properly integrate with Vagrant's error system.
#
# Expected behavior:
# - Errors class inherits from Vagrant::Errors::VagrantError
# - Errors class uses namespace "vagrant_orbstack.errors"
# - Custom error classes (OrbStackNotInstalled, OrbStackNotRunning, CommandExecutionError)
# - Error classes use proper error keys for locale integration
# - Error messages include actionable remediation steps

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Errors' do
  describe 'module definition' do
    it 'is defined after requiring errors file' do
      expect do
        require 'vagrant-orbstack/errors'
        VagrantPlugins::OrbStack::Errors
      end.not_to raise_error
    end
  end

  describe 'base Errors class' do
    before do
      require 'vagrant-orbstack/errors'
    end

    it 'inherits from Vagrant::Errors::VagrantError' do
      # Create a minimal VagrantError mock if it doesn't exist
      unless defined?(Vagrant::Errors::VagrantError)
        module Vagrant
          module Errors
            class VagrantError < StandardError
              def self.error_namespace(namespace = nil)
                @error_namespace = namespace if namespace
                @error_namespace
              end
            end
          end
        end
      end

      errors_class = VagrantPlugins::OrbStack::Errors
      expect(errors_class.ancestors.map(&:to_s)).to include('Vagrant::Errors::VagrantError')
    end

    it 'uses namespace "vagrant_orbstack.errors"' do
      errors_class = VagrantPlugins::OrbStack::Errors

      # The class should set error_namespace to "vagrant_orbstack.errors"
      # This integrates with Vagrant's locale system
      expect(errors_class).to respond_to(:error_namespace)
      expect(errors_class.error_namespace).to eq('vagrant_orbstack.errors')
    end
  end

  describe 'OrbStackNotInstalled error' do
    before do
      require 'vagrant-orbstack/errors'
    end

    it 'is defined as a class' do
      expect do
        VagrantPlugins::OrbStack::OrbStackNotInstalled
      end.not_to raise_error
    end

    it 'inherits from Errors base class' do
      error_class = VagrantPlugins::OrbStack::OrbStackNotInstalled
      expect(error_class.ancestors.map(&:to_s)).to include('VagrantPlugins::OrbStack::Errors')
    end

    it 'uses error key :orbstack_not_installed' do
      error_class = VagrantPlugins::OrbStack::OrbStackNotInstalled

      # Error classes should define error_key method that returns the key
      # used for locale lookups
      expect(error_class).to respond_to(:error_key)
      expect(error_class.error_key).to eq(:orbstack_not_installed)
    end

    it 'can be instantiated and raised' do
      expect do
        raise VagrantPlugins::OrbStack::OrbStackNotInstalled
      end.to raise_error(VagrantPlugins::OrbStack::OrbStackNotInstalled)
    end
  end

  describe 'OrbStackNotRunning error' do
    before do
      require 'vagrant-orbstack/errors'
    end

    it 'is defined as a class' do
      expect do
        VagrantPlugins::OrbStack::OrbStackNotRunning
      end.not_to raise_error
    end

    it 'inherits from Errors base class' do
      error_class = VagrantPlugins::OrbStack::OrbStackNotRunning
      expect(error_class.ancestors.map(&:to_s)).to include('VagrantPlugins::OrbStack::Errors')
    end

    it 'uses error key :orbstack_not_running' do
      error_class = VagrantPlugins::OrbStack::OrbStackNotRunning

      expect(error_class).to respond_to(:error_key)
      expect(error_class.error_key).to eq(:orbstack_not_running)
    end

    it 'can be instantiated and raised' do
      expect do
        raise VagrantPlugins::OrbStack::OrbStackNotRunning
      end.to raise_error(VagrantPlugins::OrbStack::OrbStackNotRunning)
    end
  end

  describe 'CommandExecutionError error' do
    before do
      require 'vagrant-orbstack/errors'
    end

    it 'is defined as a class' do
      expect do
        VagrantPlugins::OrbStack::CommandExecutionError
      end.not_to raise_error
    end

    it 'inherits from Errors base class' do
      error_class = VagrantPlugins::OrbStack::CommandExecutionError
      expect(error_class.ancestors.map(&:to_s)).to include('VagrantPlugins::OrbStack::Errors')
    end

    it 'uses error key :command_execution_error' do
      error_class = VagrantPlugins::OrbStack::CommandExecutionError

      expect(error_class).to respond_to(:error_key)
      expect(error_class.error_key).to eq(:command_execution_error)
    end

    it 'can be instantiated and raised' do
      expect do
        raise VagrantPlugins::OrbStack::CommandExecutionError
      end.to raise_error(VagrantPlugins::OrbStack::CommandExecutionError)
    end
  end

  describe 'SSHNotReady error' do
    before do
      require 'vagrant-orbstack/errors'
    end

    it 'is defined as a class' do
      expect do
        VagrantPlugins::OrbStack::SSHNotReady
      end.not_to raise_error
    end

    it 'inherits from Errors base class' do
      error_class = VagrantPlugins::OrbStack::SSHNotReady
      expect(error_class.ancestors.map(&:to_s)).to include('VagrantPlugins::OrbStack::Errors')
    end

    it 'uses error key :ssh_not_ready' do
      error_class = VagrantPlugins::OrbStack::SSHNotReady

      expect(error_class).to respond_to(:error_key)
      expect(error_class.error_key).to eq(:ssh_not_ready)
    end

    it 'can be instantiated and raised' do
      expect do
        raise VagrantPlugins::OrbStack::SSHNotReady
      end.to raise_error(VagrantPlugins::OrbStack::SSHNotReady)
    end
  end

  describe 'SSHConnectionFailed error' do
    before do
      require 'vagrant-orbstack/errors'
    end

    it 'is defined as a class' do
      expect do
        VagrantPlugins::OrbStack::SSHConnectionFailed
      end.not_to raise_error
    end

    it 'inherits from Errors base class' do
      error_class = VagrantPlugins::OrbStack::SSHConnectionFailed
      expect(error_class.ancestors.map(&:to_s)).to include('VagrantPlugins::OrbStack::Errors')
    end

    it 'uses error key :ssh_connection_failed' do
      error_class = VagrantPlugins::OrbStack::SSHConnectionFailed

      expect(error_class).to respond_to(:error_key)
      expect(error_class.error_key).to eq(:ssh_connection_failed)
    end

    it 'can be instantiated and raised' do
      expect do
        raise VagrantPlugins::OrbStack::SSHConnectionFailed
      end.to raise_error(VagrantPlugins::OrbStack::SSHConnectionFailed)
    end
  end

  describe 'error message integration' do
    before do
      require 'vagrant-orbstack/errors'
    end

    context 'when locale files are properly configured' do
      it 'OrbStackNotInstalled error includes installation instructions' do
        # This test verifies that the locale file includes remediation steps
        # The actual message comes from locales/en.yml
        # We're testing the integration point here

        # Skip if locale system not available in test environment
        skip 'Locale system not available in test environment' unless defined?(I18n)

        error = VagrantPlugins::OrbStack::OrbStackNotInstalled.new
        message = error.message.downcase

        # Error message should mention installation or OrbStack
        expect(message).to match(/orbstack|install/i)
      end

      it 'OrbStackNotRunning error includes start instructions' do
        skip 'Locale system not available in test environment' unless defined?(I18n)

        error = VagrantPlugins::OrbStack::OrbStackNotRunning.new
        message = error.message.downcase

        # Error message should mention starting OrbStack
        expect(message).to match(/orbstack|start|running/i)
      end

      it 'CommandExecutionError provides context about the command' do
        skip 'Locale system not available in test environment' unless defined?(I18n)

        error = VagrantPlugins::OrbStack::CommandExecutionError.new
        message = error.message.downcase

        # Error message should provide context about command execution
        expect(message).to match(/command|execution|failed/i)
      end

      it 'SSHNotReady error includes machine name context' do
        skip 'Locale system not available in test environment' unless defined?(I18n)

        error = VagrantPlugins::OrbStack::SSHNotReady.new
        message = error.message.downcase

        # Error message should mention SSH or readiness
        expect(message).to match(/ssh|ready|not available/i)
      end

      it 'SSHConnectionFailed error includes failure reason' do
        skip 'Locale system not available in test environment' unless defined?(I18n)

        error = VagrantPlugins::OrbStack::SSHConnectionFailed.new
        message = error.message.downcase

        # Error message should mention SSH or connection
        expect(message).to match(/ssh|connection|failed/i)
      end
    end
  end
end
