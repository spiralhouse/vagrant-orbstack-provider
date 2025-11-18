# frozen_string_literal: true

require_relative 'lib/vagrant-orbstack/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-orbstack'
  spec.version       = VagrantPlugins::OrbStack::VERSION
  spec.authors       = ['Vagrant OrbStack Contributors']
  spec.email         = ['noreply@example.com']

  spec.summary       = 'Vagrant provider for OrbStack'
  spec.description   = 'Enables OrbStack as a Vagrant provider for managing Linux development environments on macOS'
  spec.homepage      = 'https://github.com/example/vagrant-orbstack-provider'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.2.0'

  spec.files         = Dir['lib/**/*.rb'] + ['README.md', 'LICENSE']
  spec.require_paths = ['lib']

  # Runtime dependencies - none beyond Vagrant itself
  # Vagrant is provided by the host installation
end
