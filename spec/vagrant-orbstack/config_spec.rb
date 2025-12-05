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
# - Config validates attribute values according to rules
# - Config finalizes defaults properly

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

    it 'initializes distro as UNSET_VALUE before finalize' do
      require 'vagrant-orbstack/config'
      config = VagrantPlugins::OrbStack::Config.new

      expect(config.distro).to eq(VagrantPlugins::OrbStack::UNSET_VALUE)
    end

    it 'initializes version as UNSET_VALUE before finalize' do
      require 'vagrant-orbstack/config'
      config = VagrantPlugins::OrbStack::Config.new

      expect(config.version).to eq(VagrantPlugins::OrbStack::UNSET_VALUE)
    end

    it 'initializes machine_name as UNSET_VALUE before finalize' do
      require 'vagrant-orbstack/config'
      config = VagrantPlugins::OrbStack::Config.new

      expect(config.machine_name).to eq(VagrantPlugins::OrbStack::UNSET_VALUE)
    end

    it 'initializes ssh_username as UNSET_VALUE before finalize' do
      require 'vagrant-orbstack/config'
      config = VagrantPlugins::OrbStack::Config.new

      expect(config.ssh_username).to eq(VagrantPlugins::OrbStack::UNSET_VALUE)
    end

    it 'initializes forward_agent as UNSET_VALUE before finalize' do
      require 'vagrant-orbstack/config'
      config = VagrantPlugins::OrbStack::Config.new

      expect(config.forward_agent).to eq(VagrantPlugins::OrbStack::UNSET_VALUE)
    end

    # ============================================================================
    # LOGGER INITIALIZATION TESTS (SPI-1134)
    # ============================================================================
    #
    # These tests verify that the config class initializes a logger instance
    # for debugging configuration validation and operations.
    #
    # Reference: SPI-1134 - Logging infrastructure and debug output
    # ============================================================================

    it 'initializes a logger instance' do
      require 'vagrant-orbstack/config'
      config = VagrantPlugins::OrbStack::Config.new

      # Config should initialize @logger instance variable
      logger = config.instance_variable_get(:@logger)
      expect(logger).not_to be_nil
    end

    it 'initializes logger as a Log4r::Logger instance' do
      require 'vagrant-orbstack/config'
      config = VagrantPlugins::OrbStack::Config.new

      # Logger should be a Log4r::Logger instance
      logger = config.instance_variable_get(:@logger)
      expect(logger).to be_a(Log4r::Logger)
    end

    it 'initializes logger with correct namespace vagrant_orbstack::config' do
      require 'vagrant-orbstack/config'
      config = VagrantPlugins::OrbStack::Config.new

      # Logger should use Vagrant naming convention: vagrant_orbstack::config
      logger = config.instance_variable_get(:@logger)
      expect(logger.name).to eq('vagrant_orbstack::config')
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

    it 'provides ssh_username attribute' do
      expect(config).to respond_to(:ssh_username)
      expect(config).to respond_to(:ssh_username=)
    end

    it 'provides forward_agent attribute' do
      expect(config).to respond_to(:forward_agent)
      expect(config).to respond_to(:forward_agent=)
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

    it 'preserves custom distro value after assignment' do
      config.distro = 'debian'
      expect(config.distro).to eq('debian')
    end

    it 'preserves custom version value after assignment' do
      config.version = '11'
      expect(config.version).to eq('11')
    end

    it 'preserves custom machine_name value after assignment' do
      config.machine_name = 'test-machine'
      expect(config.machine_name).to eq('test-machine')
    end

    it 'allows setting ssh_username' do
      expect do
        config.ssh_username = 'devuser'
      end.not_to raise_error
    end

    it 'preserves custom ssh_username value after assignment' do
      config.ssh_username = 'customuser'
      expect(config.ssh_username).to eq('customuser')
    end

    it 'allows setting forward_agent to true' do
      expect do
        config.forward_agent = true
      end.not_to raise_error
    end

    it 'allows setting forward_agent to false' do
      expect do
        config.forward_agent = false
      end.not_to raise_error
    end

    it 'preserves custom forward_agent value after assignment' do
      config.forward_agent = true
      expect(config.forward_agent).to eq(true)
    end
  end

  describe '#finalize!' do
    let(:config) do
      require 'vagrant-orbstack/config'
      VagrantPlugins::OrbStack::Config.new
    end

    context 'with no values set' do
      it 'sets distro to default "ubuntu"' do
        config.finalize!
        expect(config.distro).to eq('ubuntu')
      end

      it 'sets version to nil' do
        config.finalize!
        expect(config.version).to be_nil
      end

      it 'sets machine_name to nil' do
        config.finalize!
        expect(config.machine_name).to be_nil
      end

      it 'sets ssh_username to nil' do
        config.finalize!
        expect(config.ssh_username).to be_nil
      end

      it 'sets forward_agent to false' do
        config.finalize!
        expect(config.forward_agent).to eq(false)
      end
    end

    context 'with custom values set' do
      it 'preserves custom distro value' do
        config.distro = 'debian'
        config.finalize!
        expect(config.distro).to eq('debian')
      end

      it 'preserves custom version value' do
        config.version = '11'
        config.finalize!
        expect(config.version).to eq('11')
      end

      it 'preserves custom machine_name value' do
        config.machine_name = 'my-dev-machine'
        config.finalize!
        expect(config.machine_name).to eq('my-dev-machine')
      end

      it 'preserves custom ssh_username value' do
        config.ssh_username = 'devuser'
        config.finalize!
        expect(config.ssh_username).to eq('devuser')
      end

      it 'preserves custom forward_agent true value' do
        config.forward_agent = true
        config.finalize!
        expect(config.forward_agent).to eq(true)
      end

      it 'preserves custom forward_agent false value' do
        config.forward_agent = false
        config.finalize!
        expect(config.forward_agent).to eq(false)
      end
    end

    context 'with mixed set and unset values' do
      it 'applies defaults only to unset values' do
        config.distro = 'alpine'
        # version and machine_name remain UNSET_VALUE
        config.finalize!

        expect(config.distro).to eq('alpine')
        expect(config.version).to be_nil
        expect(config.machine_name).to be_nil
      end
    end
  end

  describe '#validate' do
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
      config.finalize!
      expect do
        config.validate(machine)
      end.not_to raise_error
    end

    it 'returns a hash of errors from validate' do
      config.finalize!
      result = config.validate(machine)

      expect(result).to be_a(Hash)
    end

    it 'uses "OrbStack Provider" as error hash key' do
      config.finalize!
      result = config.validate(machine)

      expect(result).to have_key('OrbStack Provider')
    end

    context 'with valid configuration' do
      it 'returns empty errors array for default configuration' do
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'returns empty errors for custom valid distro' do
        config.distro = 'debian'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'returns empty errors for valid machine_name with hyphens' do
        config.machine_name = 'my-dev-machine'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'returns empty errors for valid machine_name with alphanumerics' do
        config.machine_name = 'test123'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'returns empty errors for valid machine_name with mixed case' do
        config.machine_name = 'MyDevMachine'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'returns empty errors when version is set' do
        config.version = '22.04'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'returns empty errors for complete valid configuration' do
        config.distro = 'ubuntu'
        config.version = '22.04'
        config.machine_name = 'my-dev-env-123'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'accepts symbol distro and converts to string' do
        config.distro = :ubuntu
        config.finalize!
        result = config.validate(machine)
        expect(result['OrbStack Provider']).to be_empty
      end

      it 'accepts valid symbol machine_name and converts to string' do
        config.machine_name = :'my-machine'
        config.finalize!
        result = config.validate(machine)
        expect(result['OrbStack Provider']).to be_empty
      end

      it 'accepts integer distro after conversion to string' do
        config.distro = 123
        config.finalize!
        result = config.validate(machine)
        # Defensive .to_s converts 123 -> "123" which is valid
        expect(result['OrbStack Provider']).to be_empty
      end

      it 'accepts integer machine_name after conversion to string' do
        config.machine_name = 123
        config.finalize!
        result = config.validate(machine)
        # Defensive .to_s converts 123 -> "123" which matches pattern
        expect(result['OrbStack Provider']).to be_empty
      end
    end

    context 'with invalid distro' do
      it 'returns error when distro is empty string' do
        config.distro = ''
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/distro.*empty/i)
      end

      it 'returns error when distro is nil after finalize' do
        # Manually set to nil to test defensive validation
        config.instance_variable_set(:@distro, nil)
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/distro/i)
      end

      it 'returns error when distro is only whitespace' do
        config.distro = '   '
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/distro.*empty/i)
      end
    end

    context 'with invalid machine_name' do
      it 'returns error when machine_name contains spaces' do
        config.machine_name = 'my machine'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/machine_name.*alphanumeric/i)
      end

      it 'returns error when machine_name contains underscores' do
        config.machine_name = 'my_machine'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/machine_name.*alphanumeric/i)
      end

      it 'returns error when machine_name contains periods' do
        config.machine_name = 'my.machine'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/machine_name.*alphanumeric/i)
      end

      it 'returns error when machine_name contains special characters' do
        config.machine_name = 'my-machine!'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/machine_name.*alphanumeric/i)
      end

      it 'returns error when machine_name starts with hyphen' do
        config.machine_name = '-my-machine'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/machine_name.*alphanumeric/i)
      end

      it 'returns error when machine_name ends with hyphen' do
        config.machine_name = 'my-machine-'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/machine_name.*alphanumeric/i)
      end
    end

    context 'with multiple validation errors' do
      it 'returns all validation errors' do
        config.distro = ''
        config.machine_name = 'invalid name with spaces'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider'].length).to eq(2)
        expect(result['OrbStack Provider']).to include(match(/distro/i))
        expect(result['OrbStack Provider']).to include(match(/machine_name/i))
      end
    end

    context 'with invalid ssh_username' do
      it 'returns error when ssh_username is empty string' do
        config.ssh_username = ''
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/ssh_username.*empty/i)
      end

      it 'returns error when ssh_username is whitespace only' do
        config.ssh_username = '   '
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/ssh_username.*empty/i)
      end

      it 'accepts nil ssh_username' do
        config.ssh_username = nil
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'accepts non-empty ssh_username' do
        config.ssh_username = 'devuser'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'accepts forward_agent true' do
        config.forward_agent = true
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'accepts forward_agent false' do
        config.forward_agent = false
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end

      it 'accepts forward_agent nil' do
        config.forward_agent = nil
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).to be_empty
      end
    end

    context 'with invalid forward_agent' do
      it 'returns error when forward_agent is string "true"' do
        config.forward_agent = 'true'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/forward_agent.*boolean/i)
      end

      it 'returns error when forward_agent is string "false"' do
        config.forward_agent = 'false'
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/forward_agent.*boolean/i)
      end

      it 'returns error when forward_agent is integer' do
        config.forward_agent = 1
        config.finalize!
        result = config.validate(machine)

        expect(result['OrbStack Provider']).not_to be_empty
        expect(result['OrbStack Provider'].first).to match(/forward_agent.*boolean/i)
      end
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
