# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::VERSION
#
# This test verifies that the VERSION constant is properly defined
# and follows semantic versioning conventions.
#
# Expected behavior:
# - VERSION constant exists and is accessible
# - VERSION follows semantic versioning format (MAJOR.MINOR.PATCH)
# - VERSION is a string
# - VERSION matches expected initial version "0.1.0"

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::VERSION' do
  describe 'version constant' do
    it 'is defined' do
      expect do
        require 'vagrant-orbstack/version'
        VagrantPlugins::OrbStack::VERSION
      end.not_to raise_error
    end

    it 'is a string' do
      require 'vagrant-orbstack/version'
      expect(VagrantPlugins::OrbStack::VERSION).to be_a(String)
    end

    it 'follows semantic versioning format' do
      require 'vagrant-orbstack/version'
      version = VagrantPlugins::OrbStack::VERSION

      # Semantic versioning regex: MAJOR.MINOR.PATCH with optional pre-release/build metadata
      semver_pattern = /\A\d+\.\d+\.\d+(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?\z/

      expect(version).to match(semver_pattern)
    end

    it 'is set to initial version 0.1.0' do
      require 'vagrant-orbstack/version'
      expect(VagrantPlugins::OrbStack::VERSION).to eq('0.1.0')
    end
  end

  describe 'version accessibility' do
    it 'can be accessed via module path' do
      require 'vagrant-orbstack/version'
      expect(VagrantPlugins::OrbStack::VERSION).not_to be_nil
    end

    it 'does not change between accesses' do
      require 'vagrant-orbstack/version'
      first_access = VagrantPlugins::OrbStack::VERSION
      second_access = VagrantPlugins::OrbStack::VERSION

      expect(first_access).to eq(second_access)
    end
  end
end
