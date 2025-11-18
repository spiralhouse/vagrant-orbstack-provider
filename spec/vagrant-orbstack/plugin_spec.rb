# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Plugin
#
# This test verifies that the plugin correctly registers with Vagrant's
# plugin system (API v2) and declares all necessary components.
#
# Expected behavior:
# - Plugin can be required without errors
# - Plugin inherits from Vagrant.plugin("2")
# - Plugin registers provider component named :orbstack
# - Plugin registers config component for :orbstack provider
# - Plugin has correct name and description

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Plugin' do
  before(:all) do
    require 'vagrant-orbstack/plugin'
  end

  describe 'plugin loading' do
    it 'can be required without errors' do
      expect do
        require 'vagrant-orbstack/plugin'
      end.not_to raise_error
    end
  end

  describe 'plugin registration' do
    let(:plugin_class) { VagrantPlugins::OrbStack::Plugin }

    it 'inherits from Vagrant.plugin(2)' do
      expect(plugin_class.superclass).to eq(Vagrant.plugin('2'))
    end

    it 'has a name' do
      expect(plugin_class.name).to eq('VagrantPlugins::OrbStack::Plugin')
    end
  end

  describe 'provider registration' do
    let(:plugin_class) { VagrantPlugins::OrbStack::Plugin }

    it 'registers the orbstack provider' do
      # Vagrant plugin v2 uses a components hash to track registered components
      # The provider should be registered under :provider with name :orbstack
      providers = plugin_class.components.providers
      expect(providers).to have_key(:orbstack)
    end

    it 'provides a description for the provider' do
      # Plugin should have a description method or constant
      expect(plugin_class).to respond_to(:description).or(
        satisfy { |klass| klass.const_defined?(:DESCRIPTION) }
      )
    end
  end

  describe 'config registration' do
    let(:plugin_class) { VagrantPlugins::OrbStack::Plugin }

    it 'registers config for orbstack provider' do
      # Config should be registered under :config with scope :provider
      configs = plugin_class.components.configs
      expect(configs).to have_key(:provider)
      expect(configs[:provider]).to have_key(:orbstack)
    end
  end

  describe 'plugin metadata' do
    let(:plugin_class) { VagrantPlugins::OrbStack::Plugin }

    it "declares plugin name as 'OrbStack'" do
      # Plugin v2 API expects a name to be declared
      # This is typically done via `name "PluginName"` in the plugin class
      expect(plugin_class.name).to include('OrbStack')
    end
  end
end
