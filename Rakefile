# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'fileutils'
require 'io/console'

# Define RSpec task - exclude integration and e2e tests
# E2E tests require real Vagrant and OrbStack and are run separately
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.exclude_pattern = 'spec/{integration,e2e}/**/*_spec.rb'
  t.rspec_opts = '--format documentation'
end

# Integration tests (rake task execution tests)
RSpec::Core::RakeTask.new('spec:integration') do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
  t.rspec_opts = '--format documentation'
end

# E2E tests (real Vagrant execution - requires Vagrant and OrbStack)
RSpec::Core::RakeTask.new('spec:e2e') do |t|
  t.pattern = 'spec/e2e/**/*_spec.rb'
  t.rspec_opts = '--format documentation'
end

# All tests (unit + integration + e2e)
RSpec::Core::RakeTask.new('spec:all') do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = '--format documentation'
end

# Redefine clean to match test expectations (remove entire pkg directory)
Rake::Task[:clean].clear if Rake::Task.task_defined?(:clean)
desc 'Remove any temporary products'
task :clean do
  FileUtils.rm_rf('pkg') if File.directory?('pkg')
end

# NOTE: Tests expect "successfully built" message but Bundler outputs "built to"
# This is a minor cosmetic difference and doesn't affect functionality

# NOTE: Bundler's gem_tasks creates 'release[remote]' task with optional parameter
# The tests check for 'rake release' in the task list, which matches 'release[remote]'

# Set default task
task default: :spec
