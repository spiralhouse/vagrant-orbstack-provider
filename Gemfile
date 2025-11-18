# frozen_string_literal: true

source 'https://rubygems.org'

# NOTE: Vagrant is expected to be installed on the system.
# Plugin development requires Vagrant to be available.
# For testing without Vagrant installed, we'll mock the necessary components.

group :development, :test do
  gem 'pry', '~> 0.14'
  gem 'rspec', '~> 3.12'
  gem 'rubocop', '~> 1.50'
  gem 'simplecov', '~> 0.22', require: false
end

# Load gemspec dependencies
gemspec
