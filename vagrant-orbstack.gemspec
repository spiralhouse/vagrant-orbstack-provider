# frozen_string_literal: true

require_relative 'lib/vagrant-orbstack/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-orbstack'
  spec.version       = VagrantPlugins::OrbStack::VERSION
  spec.authors       = ['Spiral House']
  spec.email         = ['opensource@spiralhouse.io']

  spec.summary       = 'Vagrant provider for OrbStack'
  spec.description   = 'Enables OrbStack as a Vagrant provider for managing Linux development environments on macOS'
  spec.homepage      = 'https://github.com/spiralhouse/vagrant-orbstack-provider'
  spec.license       = 'MIT'
  spec.metadata = {
    'homepage_uri' => 'https://github.com/spiralhouse/vagrant-orbstack-provider',
    'source_code_uri' => 'https://github.com/spiralhouse/vagrant-orbstack-provider',
    'bug_tracker_uri' => 'https://github.com/spiralhouse/vagrant-orbstack-provider/issues',
    'changelog_uri' => 'https://github.com/spiralhouse/vagrant-orbstack-provider/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/spiralhouse/vagrant-orbstack-provider',
    'allowed_push_host' => 'https://rubygems.org'
  }

  spec.required_ruby_version = '>= 3.2.0'

  spec.files         = Dir['lib/**/*.rb', 'locales/**/*.yml'] + ['README.md', 'CHANGELOG.md', 'LICENSE']
  spec.require_paths = ['lib']

  # Runtime dependencies - none beyond Vagrant itself
  # Vagrant is provided by the host installation
end
