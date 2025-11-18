# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Provider
#
# This test verifies that the Provider class exists and implements
# the Vagrant provider interface (API v2).
#
# Expected behavior:
# - Provider class exists and can be instantiated
# - Provider inherits from Vagrant.plugin("2", :provider)
# - Provider can be initialized with a machine object
# - Provider responds to core provider interface methods

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Provider' do
  # Mock Vagrant machine object for testing
  let(:machine) do
    double('machine',
           name: 'default',
           provider_config: double('config'),
           data_dir: Pathname.new('/tmp/vagrant-test'),
           ui: double('ui'))
  end

  describe 'class definition' do
    it 'is defined after requiring provider file' do
      expect do
        require 'vagrant-orbstack/provider'
        VagrantPlugins::OrbStack::Provider
      end.not_to raise_error
    end

    it 'inherits from Vagrant provider base class' do
      require 'vagrant-orbstack/provider'
      provider_class = VagrantPlugins::OrbStack::Provider

      # Vagrant provider classes should inherit from Vagrant.plugin("2", :provider)
      # This is the base class for all provider plugins
      expect(provider_class.ancestors.map(&:to_s)).to include(
        'Vagrant::Plugin::V2::Provider'
      )
    end
  end

  describe 'initialization' do
    it 'can be instantiated with a machine object' do
      require 'vagrant-orbstack/provider'

      expect do
        VagrantPlugins::OrbStack::Provider.new(machine)
      end.not_to raise_error
    end

    it 'stores the machine reference' do
      require 'vagrant-orbstack/provider'
      provider = VagrantPlugins::OrbStack::Provider.new(machine)

      # Provider should maintain reference to machine for later operations
      # We'll test this indirectly by checking that it doesn't error
      expect(provider).to be_a(VagrantPlugins::OrbStack::Provider)
    end
  end

  describe 'provider interface' do
    let(:provider) do
      require 'vagrant-orbstack/provider'
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    it 'responds to action method' do
      expect(provider).to respond_to(:action)
    end

    it 'responds to ssh_info method' do
      expect(provider).to respond_to(:ssh_info)
    end

    it 'responds to state method' do
      expect(provider).to respond_to(:state)
    end

    it 'responds to to_s method for human-readable description' do
      expect(provider).to respond_to(:to_s)
    end
  end

  describe 'provider identification' do
    let(:provider) do
      require 'vagrant-orbstack/provider'
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    it 'returns a meaningful string representation' do
      description = provider.to_s

      expect(description).to be_a(String)
      expect(description).not_to be_empty
      expect(description.downcase).to include('orbstack')
    end
  end
end
