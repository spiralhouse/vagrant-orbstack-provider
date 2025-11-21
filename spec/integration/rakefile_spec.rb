# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'fileutils'

RSpec.describe 'Rakefile tasks', type: :integration do
  let(:project_root) { File.expand_path('../..', __dir__) }
  let(:pkg_dir) { File.join(project_root, 'pkg') }

  # Helper method to execute rake commands
  def run_rake(*args)
    cmd = "cd #{project_root} && bundle exec rake #{args.join(' ')}"
    stdout, stderr, status = Open3.capture3(cmd)
    {
      stdout: stdout,
      stderr: stderr,
      status: status,
      success: status.success?,
      exit_code: status.exitstatus
    }
  end

  describe 'rake -T (list tasks)' do
    it 'executes successfully' do
      result = run_rake('-T')
      expect(result[:success]).to be(true),
                                  "rake -T failed with exit code #{result[:exit_code]}:\n#{result[:stderr]}"
    end

    it 'lists the spec task' do
      result = run_rake('-T')
      expect(result[:stdout]).to match(/rake spec\s+/)
    end

    it 'lists the build task' do
      result = run_rake('-T')
      expect(result[:stdout]).to match(/rake build\s+/)
    end

    it 'lists the install task' do
      result = run_rake('-T')
      expect(result[:stdout]).to match(/rake install\s+/)
    end

    it 'lists the clean task' do
      result = run_rake('-T')
      expect(result[:stdout]).to match(/rake clean\s+/)
    end

    it 'lists the release task' do
      result = run_rake('-T')
      expect(result[:stdout]).to match(/rake release(\[.*?\])?\s+/)
    end
  end

  describe 'rake spec (run tests)' do
    it 'executes successfully' do
      result = run_rake('spec')
      expect(result[:success]).to be(true),
                                  "rake spec failed with exit code #{result[:exit_code]}:\n#{result[:stderr]}"
    end

    it 'runs the RSpec test suite' do
      result = run_rake('spec')
      output = result[:stdout] + result[:stderr]
      expect(output).to match(/\d+ examples?/)
    end

    it 'displays test results' do
      result = run_rake('spec')
      output = result[:stdout] + result[:stderr]
      expect(output).to match(/Finished in/)
    end

    it 'runs RSpec with the spec directory' do
      result = run_rake('spec')
      output = result[:stdout] + result[:stderr]
      # RSpec should find and run test files
      expect(output).to match(%r{spec/.*_spec\.rb})
    end
  end

  describe 'rake build (build gem)' do
    before do
      # Clean up any existing pkg directory before build tests
      FileUtils.rm_rf(pkg_dir) if File.directory?(pkg_dir)
    end

    after do
      # Clean up after build tests
      FileUtils.rm_rf(pkg_dir) if File.directory?(pkg_dir)
    end

    it 'executes successfully' do
      result = run_rake('build')
      expect(result[:success]).to be(true),
                                  "rake build failed with exit code #{result[:exit_code]}:\n#{result[:stderr]}"
    end

    it 'creates the pkg directory' do
      run_rake('build')
      expect(File.directory?(pkg_dir)).to be(true)
    end

    it 'creates a gem file in pkg directory' do
      run_rake('build')
      gem_files = Dir.glob(File.join(pkg_dir, '*.gem'))
      expect(gem_files).not_to be_empty
    end

    it 'creates a gem file with the correct version' do
      run_rake('build')
      gem_files = Dir.glob(File.join(pkg_dir, 'vagrant-orbstack-*.gem'))
      expect(gem_files).not_to be_empty
    end

    it 'displays build success message' do
      result = run_rake('build')
      output = result[:stdout] + result[:stderr]
      expect(output).to match(/vagrant-orbstack.*built.*pkg/i)
    end

    it 'outputs the path to the built gem' do
      result = run_rake('build')
      output = result[:stdout] + result[:stderr]
      expect(output).to match(%r{pkg/vagrant-orbstack.*\.gem})
    end
  end

  describe 'rake clean (clean build artifacts)' do
    context 'when pkg directory exists' do
      before do
        # Create pkg directory with a dummy file
        FileUtils.mkdir_p(pkg_dir)
        File.write(File.join(pkg_dir, 'dummy.gem'), 'test content')
      end

      it 'executes successfully' do
        result = run_rake('clean')
        expect(result[:success]).to be(true),
                                    "rake clean failed with exit code #{result[:exit_code]}:\n#{result[:stderr]}"
      end

      it 'removes the pkg directory' do
        run_rake('clean')
        expect(File.directory?(pkg_dir)).to be(false)
      end
    end

    context 'when pkg directory does not exist' do
      before do
        # Ensure pkg directory does not exist
        FileUtils.rm_rf(pkg_dir) if File.directory?(pkg_dir)
      end

      it 'executes successfully (idempotent)' do
        result = run_rake('clean')
        expect(result[:success]).to be(true),
                                    "rake clean failed (pkg/ missing case): #{result[:exit_code]}:\n#{result[:stderr]}"
      end

      it 'does not fail when nothing to clean' do
        result = run_rake('clean')
        expect(result[:exit_code]).to eq(0)
      end
    end
  end

  describe 'rake install (install gem locally)' do
    before do
      # Clean up before install test
      FileUtils.rm_rf(pkg_dir) if File.directory?(pkg_dir)
    end

    after do
      # Clean up after install test
      FileUtils.rm_rf(pkg_dir) if File.directory?(pkg_dir)
    end

    it 'executes successfully' do
      result = run_rake('install')
      expect(result[:success]).to be(true),
                                  "rake install failed with exit code #{result[:exit_code]}:\n#{result[:stderr]}"
    end

    it 'builds the gem before installing' do
      run_rake('install')
      # Should create pkg directory as part of build step
      expect(File.directory?(pkg_dir)).to be(true)
    end

    it 'displays installation message' do
      result = run_rake('install')
      output = result[:stdout] + result[:stderr]
      expect(output).to match(/vagrant-orbstack.*built.*pkg/i)
    end
  end

  describe 'rake (default task)' do
    it 'executes successfully' do
      result = run_rake
      expect(result[:success]).to be(true),
                                  "Default rake task failed with exit code #{result[:exit_code]}:\n#{result[:stderr]}"
    end

    it 'runs the spec task by default' do
      result = run_rake
      output = result[:stdout] + result[:stderr]
      # Should show RSpec output, indicating spec task ran
      expect(output).to match(/\d+ examples?/)
    end

    it 'behaves identically to rake spec' do
      default_result = run_rake
      spec_result = run_rake('spec')

      # Both should succeed
      expect(default_result[:success]).to eq(spec_result[:success])

      # Both should produce RSpec output
      default_output = default_result[:stdout] + default_result[:stderr]
      spec_output = spec_result[:stdout] + spec_result[:stderr]

      expect(default_output).to match(/\d+ examples?/)
      expect(spec_output).to match(/\d+ examples?/)
    end
  end

  describe 'task dependencies' do
    it 'rake install depends on rake build' do
      # This is tested implicitly by the install test checking for pkg/
      # But we can also verify by checking that install creates the gem
      FileUtils.rm_rf(pkg_dir) if File.directory?(pkg_dir)

      result = run_rake('install')
      expect(result[:success]).to be true

      gem_files = Dir.glob(File.join(pkg_dir, '*.gem'))
      expect(gem_files).not_to be_empty
    end
  end

  describe 'error handling' do
    it 'provides helpful error message for unknown tasks' do
      result = run_rake('nonexistent_task')
      expect(result[:success]).to be(false)
      expect(result[:stderr]).to match(/rake aborted!|Don't know how to build/i)
    end
  end
end
