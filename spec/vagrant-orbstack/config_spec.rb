# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Config
#
# This test verifies that the Config class exists and implements
# the Vagrant config interface (API v2) for provider configuration.
#
# Expected behavior:
# - Config class exists and can be instantiated
# - Config inherits from Vagrant.plugin("2", :config)
# - Config can be initialized without arguments
# - Config provides configuration attributes (distro, version, machine_name)
# - Config responds to validation method

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Config' do
  describe 'class definition' do
    it 'is defined after requiring config file' do
      expect do
        require 'vagrant-orbstack/config'
        VagrantPlugins::OrbStack::Config
      end.not_to raise_error
    end

    it 'inherits from Vagrant config base class' do
      require 'vagrant-orbstack/config'
      config_class = VagrantPlugins::OrbStack::Config

      # Vagrant config classes should inherit from Vagrant.plugin("2", :config)
      expect(config_class.ancestors.map(&:to_s)).to include(
        'Vagrant::Plugin::V2::Config'
      )
    end
  end

  describe 'initialization' do
    it 'can be instantiated without arguments' do
      require 'vagrant-orbstack/config'

      expect do
        VagrantPlugins::OrbStack::Config.new
      end.not_to raise_error
    end

    it 'creates a new instance' do
      require 'vagrant-orbstack/config'
      config = VagrantPlugins::OrbStack::Config.new

      expect(config).to be_a(VagrantPlugins::OrbStack::Config)
    end
  end

  describe 'configuration attributes' do
    let(:config) do
      require 'vagrant-orbstack/config'
      VagrantPlugins::OrbStack::Config.new
    end

    it 'provides distro attribute' do
      expect(config).to respond_to(:distro)
      expect(config).to respond_to(:distro=)
    end

    it 'provides version attribute' do
      expect(config).to respond_to(:version)
      expect(config).to respond_to(:version=)
    end

    it 'provides machine_name attribute' do
      expect(config).to respond_to(:machine_name)
      expect(config).to respond_to(:machine_name=)
    end
  end

  describe 'attribute assignment' do
    let(:config) do
      require 'vagrant-orbstack/config'
      VagrantPlugins::OrbStack::Config.new
    end

    it 'allows setting distro' do
      expect do
        config.distro = 'ubuntu'
      end.not_to raise_error
    end

    it 'allows setting version' do
      expect do
        config.version = '22.04'
      end.not_to raise_error
    end

    it 'allows setting machine_name' do
      expect do
        config.machine_name = 'my-custom-vm'
      end.not_to raise_error
    end
  end

  describe 'validation interface' do
    let(:config) do
      require 'vagrant-orbstack/config'
      VagrantPlugins::OrbStack::Config.new
    end

    let(:machine) do
      double('machine')
    end

    it 'responds to validate method' do
      expect(config).to respond_to(:validate)
    end

    it 'accepts a machine parameter for validation' do
      expect do
        config.validate(machine)
      end.not_to raise_error
    end

    it 'returns a hash of errors from validate' do
      result = config.validate(machine)

      expect(result).to be_a(Hash)
    end

    it 'uses provider namespace in error hash keys' do
      result = config.validate(machine)

      # Vagrant convention: errors are namespaced by component
      # Expected key format: "OrbStack Provider" or similar
      expect(result.keys).to all(be_a(String))
    end
  end

  describe 'default values' do
    let(:config) do
      require 'vagrant-orbstack/config'
      VagrantPlugins::OrbStack::Config.new
    end

    it 'has distro attribute initialized' do
      # Should either be nil (unset) or have a default value
      expect { config.distro }.not_to raise_error
    end

    it 'has version attribute initialized' do
      expect { config.version }.not_to raise_error
    end

    it 'has machine_name attribute initialized' do
      expect { config.machine_name }.not_to raise_error
    end
  end
end
