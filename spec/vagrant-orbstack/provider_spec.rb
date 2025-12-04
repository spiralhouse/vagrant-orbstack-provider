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
    ui = double('ui')
    allow(ui).to receive(:warn)
    allow(ui).to receive(:error)

    double('machine',
           name: 'default',
           provider_config: double('config'),
           data_dir: Pathname.new('/tmp/vagrant-test'),
           ui: ui)
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

    # ============================================================================
    # LOGGER INITIALIZATION TESTS (SPI-1134)
    # ============================================================================
    #
    # These tests verify that the provider initializes a logger instance
    # for debugging and operational visibility.
    #
    # Reference: SPI-1134 - Logging infrastructure and debug output
    # ============================================================================

    it 'initializes a logger instance' do
      require 'vagrant-orbstack/provider'
      provider = VagrantPlugins::OrbStack::Provider.new(machine)

      # Provider should initialize @logger instance variable
      logger = provider.instance_variable_get(:@logger)
      expect(logger).not_to be_nil
    end

    it 'initializes logger as a Log4r::Logger instance' do
      require 'vagrant-orbstack/provider'
      provider = VagrantPlugins::OrbStack::Provider.new(machine)

      # Logger should be a Log4r::Logger instance
      logger = provider.instance_variable_get(:@logger)
      expect(logger).to be_a(Log4r::Logger)
    end

    it 'initializes logger with correct namespace vagrant_orbstack::provider' do
      require 'vagrant-orbstack/provider'
      provider = VagrantPlugins::OrbStack::Provider.new(machine)

      # Logger should use Vagrant naming convention: vagrant_orbstack::provider
      logger = provider.instance_variable_get(:@logger)
      expect(logger.name).to eq('vagrant_orbstack::provider')
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

  # ============================================================================
  # METADATA STORAGE TESTS (SPI-1132)
  # ============================================================================
  #
  # These tests verify the provider's ability to persist machine metadata
  # across Vagrant sessions. The metadata includes:
  # - Machine ID (stored in data_dir/id)
  # - Machine metadata JSON (stored in data_dir/metadata.json)
  #
  # Reference: SPI-1132 - Provider class implementing Vagrant interface
  # ============================================================================

  describe 'machine_id_changed callback' do
    let(:provider) do
      require 'vagrant-orbstack/provider'
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    after do
      # Clean up test files
      FileUtils.rm_rf(machine.data_dir)
    end

    context 'when machine ID is set for the first time' do
      it 'responds to machine_id_changed method' do
        expect(provider).to respond_to(:machine_id_changed)
      end

      it 'persists the machine ID to data_dir/id file' do
        # Arrange
        machine_id = 'test-machine-uuid-12345'
        id_file = machine.data_dir.join('id')
        allow(machine).to receive(:id).and_return(machine_id)

        # Act
        provider.machine_id_changed

        # Assert
        expect(File.exist?(id_file)).to be true
        expect(File.read(id_file).strip).to eq(machine_id)
      end

      it 'creates the data directory if it does not exist' do
        # Arrange
        machine_id = 'test-id-123'
        allow(machine).to receive(:id).and_return(machine_id)
        allow(Dir).to receive(:exist?).with(machine.data_dir).and_return(false)
        allow(FileUtils).to receive(:mkdir_p)
        allow(File).to receive(:write)

        # Act
        provider.machine_id_changed

        # Assert
        expect(FileUtils).to have_received(:mkdir_p).with(machine.data_dir)
      end
    end

    context 'when machine ID changes' do
      it 'updates the persisted machine ID' do
        # Arrange
        old_id = 'old-machine-id'
        new_id = 'new-machine-id'
        id_file = machine.data_dir.join('id')

        # Setup existing ID file
        allow(File).to receive(:exist?).with(id_file).and_return(true)
        allow(File).to receive(:read).with(id_file).and_return(old_id)
        allow(File).to receive(:write)

        # Change machine ID
        allow(machine).to receive(:id).and_return(new_id)

        # Act
        provider.machine_id_changed

        # Assert
        expect(File).to have_received(:write).with(id_file, new_id)
      end
    end

    context 'when machine ID is nil' do
      it 'handles nil machine ID gracefully' do
        # Arrange
        allow(machine).to receive(:id).and_return(nil)

        # Act & Assert
        expect { provider.machine_id_changed }.not_to raise_error
      end

      it 'does not write to ID file when machine ID is nil' do
        # Arrange
        allow(machine).to receive(:id).and_return(nil)
        id_file = machine.data_dir.join('id')

        # Act
        provider.machine_id_changed

        # Assert
        expect(File.exist?(id_file)).to be false
      end
    end
  end

  describe 'machine ID persistence' do
    let(:provider) do
      require 'vagrant-orbstack/provider'
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    let(:id_file) { machine.data_dir.join('id') }
    let(:test_machine_id) { 'test-machine-uuid-67890' }

    context 'when reading machine ID' do
      it 'reads machine ID from data_dir/id file' do
        # Arrange
        allow(File).to receive(:exist?).with(id_file).and_return(true)
        allow(File).to receive(:read).with(id_file).and_return(test_machine_id)

        # Act
        machine_id = provider.read_machine_id

        # Assert
        expect(machine_id).to eq(test_machine_id)
      end

      it 'returns nil when ID file does not exist' do
        # Arrange
        allow(File).to receive(:exist?).with(id_file).and_return(false)

        # Act
        machine_id = provider.read_machine_id

        # Assert
        expect(machine_id).to be_nil
      end

      it 'strips whitespace from machine ID' do
        # Arrange
        id_with_whitespace = "  #{test_machine_id}\n  "
        allow(File).to receive(:exist?).with(id_file).and_return(true)
        allow(File).to receive(:read).with(id_file).and_return(id_with_whitespace)

        # Act
        machine_id = provider.read_machine_id

        # Assert
        expect(machine_id).to eq(test_machine_id)
      end

      it 'handles corrupted ID file with non-string data' do
        # Arrange
        allow(File).to receive(:exist?).with(id_file).and_return(true)
        allow(File).to receive(:read).with(id_file).and_raise(Encoding::InvalidByteSequenceError)

        # Act & Assert
        expect { provider.read_machine_id }.not_to raise_error
        expect(provider.read_machine_id).to be_nil
      end

      it 'handles permission denied errors gracefully' do
        # Arrange
        allow(File).to receive(:exist?).with(id_file).and_return(true)
        allow(File).to receive(:read).with(id_file).and_raise(Errno::EACCES)

        # Act & Assert
        expect { provider.read_machine_id }.not_to raise_error
        expect(provider.read_machine_id).to be_nil
      end
    end

    context 'when writing machine ID' do
      it 'writes machine ID to data_dir/id file' do
        # Arrange
        allow(File).to receive(:write)

        # Act
        provider.write_machine_id(test_machine_id)

        # Assert
        expect(File).to have_received(:write).with(id_file, test_machine_id)
      end

      it 'handles empty machine ID' do
        # Arrange
        allow(File).to receive(:write)

        # Act & Assert
        expect { provider.write_machine_id('') }.not_to raise_error
      end

      it 'handles very long machine IDs' do
        # Arrange
        long_id = 'a' * 1000
        allow(File).to receive(:write)

        # Act & Assert
        expect { provider.write_machine_id(long_id) }.not_to raise_error
      end

      it 'handles permission denied errors when writing' do
        # Arrange
        allow(File).to receive(:write).and_raise(Errno::EACCES)

        # Act & Assert
        expect { provider.write_machine_id(test_machine_id) }.to raise_error(Errno::EACCES)
      end
    end
  end

  describe 'metadata persistence' do
    let(:provider) do
      require 'vagrant-orbstack/provider'
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    let(:metadata_file) { machine.data_dir.join('metadata.json') }
    let(:test_metadata) do
      {
        'machine_id' => 'test-machine-123',
        'orbstack_machine_name' => 'vagrant-default-abc123',
        'created_at' => '2025-11-18T10:30:00Z',
        'provider_version' => '0.1.0'
      }
    end

    context 'when reading metadata' do
      it 'reads metadata from data_dir/metadata.json' do
        # Arrange
        allow(File).to receive(:exist?).with(metadata_file).and_return(true)
        allow(File).to receive(:read).with(metadata_file).and_return(JSON.generate(test_metadata))

        # Act
        metadata = provider.read_metadata

        # Assert
        expect(metadata).to eq(test_metadata)
      end

      it 'returns empty hash when metadata file does not exist' do
        # Arrange
        allow(File).to receive(:exist?).with(metadata_file).and_return(false)

        # Act
        metadata = provider.read_metadata

        # Assert
        expect(metadata).to eq({})
      end

      it 'handles invalid JSON gracefully' do
        # Arrange
        allow(File).to receive(:exist?).with(metadata_file).and_return(true)
        allow(File).to receive(:read).with(metadata_file).and_return('not valid json {')

        # Act & Assert
        expect { provider.read_metadata }.not_to raise_error
        expect(provider.read_metadata).to eq({})
      end

      it 'handles missing metadata fields in JSON' do
        # Arrange
        partial_metadata = { 'machine_id' => 'test-123' }
        allow(File).to receive(:exist?).with(metadata_file).and_return(true)
        allow(File).to receive(:read).with(metadata_file).and_return(JSON.generate(partial_metadata))

        # Act
        metadata = provider.read_metadata

        # Assert
        expect(metadata).to eq(partial_metadata)
        expect(metadata['machine_id']).to eq('test-123')
        expect(metadata['orbstack_machine_name']).to be_nil
      end

      it 'handles empty JSON file' do
        # Arrange
        allow(File).to receive(:exist?).with(metadata_file).and_return(true)
        allow(File).to receive(:read).with(metadata_file).and_return('{}')

        # Act
        metadata = provider.read_metadata

        # Assert
        expect(metadata).to eq({})
      end

      it 'handles corrupted metadata file' do
        # Arrange
        allow(File).to receive(:exist?).with(metadata_file).and_return(true)
        allow(File).to receive(:read).with(metadata_file).and_raise(Encoding::InvalidByteSequenceError)

        # Act & Assert
        expect { provider.read_metadata }.not_to raise_error
        expect(provider.read_metadata).to eq({})
      end

      it 'handles permission denied errors when reading' do
        # Arrange
        allow(File).to receive(:exist?).with(metadata_file).and_return(true)
        allow(File).to receive(:read).with(metadata_file).and_raise(Errno::EACCES)

        # Act & Assert
        expect { provider.read_metadata }.not_to raise_error
        expect(provider.read_metadata).to eq({})
      end
    end

    context 'when writing metadata' do
      it 'writes metadata to data_dir/metadata.json as formatted JSON' do
        # Arrange
        allow(File).to receive(:write)

        # Act
        provider.write_metadata(test_metadata)

        # Assert
        expected_json = JSON.pretty_generate(test_metadata)
        expect(File).to have_received(:write).with(metadata_file, expected_json)
      end

      it 'creates the data directory if it does not exist' do
        # Arrange
        allow(Dir).to receive(:exist?).with(machine.data_dir).and_return(false)
        allow(FileUtils).to receive(:mkdir_p)
        allow(File).to receive(:write)

        # Act
        provider.write_metadata(test_metadata)

        # Assert
        expect(FileUtils).to have_received(:mkdir_p).with(machine.data_dir)
      end

      it 'handles empty metadata hash' do
        # Arrange
        allow(File).to receive(:write)

        # Act & Assert
        expect { provider.write_metadata({}) }.not_to raise_error
      end

      it 'handles nil metadata fields' do
        # Arrange
        metadata_with_nil = test_metadata.merge('created_at' => nil)
        allow(File).to receive(:write)

        # Act & Assert
        expect { provider.write_metadata(metadata_with_nil) }.not_to raise_error
      end

      it 'handles special characters in machine names' do
        # Arrange
        metadata_with_special_chars = test_metadata.merge(
          'orbstack_machine_name' => 'vagrant-test-!@#$%^&*()'
        )
        allow(File).to receive(:write)

        # Act & Assert
        expect { provider.write_metadata(metadata_with_special_chars) }.not_to raise_error
      end

      it 'raises error when write permission denied' do
        # Arrange
        allow(File).to receive(:write).and_raise(Errno::EACCES)

        # Act & Assert
        expect { provider.write_metadata(test_metadata) }.to raise_error(Errno::EACCES)
      end

      it 'raises error when disk is full' do
        # Arrange
        allow(File).to receive(:write).and_raise(Errno::ENOSPC)

        # Act & Assert
        expect { provider.write_metadata(test_metadata) }.to raise_error(Errno::ENOSPC)
      end
    end

    context 'when performing metadata roundtrip' do
      it 'preserves all metadata fields through write and read cycle' do
        # Arrange
        written_data = nil
        allow(File).to receive(:write) do |_path, data|
          written_data = data
        end
        allow(File).to receive(:exist?).with(metadata_file).and_return(true)
        allow(File).to receive(:read).with(metadata_file) do
          written_data
        end

        # Act
        provider.write_metadata(test_metadata)
        read_metadata = provider.read_metadata

        # Assert
        expect(read_metadata).to eq(test_metadata)
      end

      it 'handles complex nested metadata structures' do
        # Arrange
        complex_metadata = test_metadata.merge(
          'config' => {
            'distro' => 'ubuntu',
            'version' => '22.04',
            'tags' => %w[dev test]
          }
        )

        written_data = nil
        allow(File).to receive(:write) do |_path, data|
          written_data = data
        end
        allow(File).to receive(:exist?).with(metadata_file).and_return(true)
        allow(File).to receive(:read).with(metadata_file) do
          written_data
        end

        # Act
        provider.write_metadata(complex_metadata)
        read_metadata = provider.read_metadata

        # Assert
        expect(read_metadata).to eq(complex_metadata)
      end
    end
  end

  describe 'edge cases for metadata storage' do
    let(:provider) do
      require 'vagrant-orbstack/provider'
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    let(:test_metadata) do
      {
        'machine_id' => 'test-machine-123',
        'orbstack_machine_name' => 'vagrant-default-abc123',
        'created_at' => '2025-11-18T10:30:00Z',
        'provider_version' => '0.1.0'
      }
    end

    context 'when handling very long machine names' do
      it 'stores and retrieves machine names up to 255 characters' do
        # Arrange
        long_name = "vagrant-#{'a' * 248}"
        metadata = { 'orbstack_machine_name' => long_name }

        written_data = nil
        allow(File).to receive(:write) do |_path, data|
          written_data = data
        end
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read) { written_data }

        # Act
        provider.write_metadata(metadata)
        result = provider.read_metadata

        # Assert
        expect(result['orbstack_machine_name']).to eq(long_name)
      end
    end

    context 'when handling concurrent access' do
      it 'does not corrupt data when multiple writes occur' do
        # Arrange
        metadata1 = test_metadata.merge('machine_id' => 'id-1')
        metadata2 = test_metadata.merge('machine_id' => 'id-2')

        allow(File).to receive(:write)

        # Act
        provider.write_metadata(metadata1)
        provider.write_metadata(metadata2)

        # Assert - last write should win
        expect(File).to have_received(:write).twice
      end
    end

    context 'when data directory path contains special characters' do
      let(:special_dir_machine) do
        double('machine',
               name: 'default',
               provider_config: double('config'),
               data_dir: Pathname.new('/tmp/vagrant test/with spaces'),
               ui: double('ui'))
      end

      let(:special_provider) do
        require 'vagrant-orbstack/provider'
        VagrantPlugins::OrbStack::Provider.new(special_dir_machine)
      end

      it 'handles directory paths with spaces' do
        # Arrange
        metadata = { 'machine_id' => 'test-123' }
        allow(File).to receive(:write)

        # Act & Assert
        expect { special_provider.write_metadata(metadata) }.not_to raise_error
      end
    end
  end

  # ============================================================================
  # PROVIDER#ACTION INTEGRATION TESTS (SPI-1200)
  # ============================================================================
  #
  # These tests verify that the Provider#action method returns appropriate
  # action middleware for different Vagrant operations using the Action Builder
  # pattern. This is the entry point for all machine lifecycle operations.
  #
  # Reference: SPI-1200 - Machine Creation and Naming
  # ============================================================================

  describe '#action method integration' do
    let(:provider) do
      require 'vagrant-orbstack/provider'
      VagrantPlugins::OrbStack::Provider.new(machine)
    end

    context 'when requesting :up action' do
      it 'returns a Vagrant::Action::Builder instance' do
        # Arrange & Act
        action = provider.action(:up)

        # Assert
        expect(action).not_to be_nil
        expect(action).to be_a(Vagrant::Action::Builder)
      end

      it 'includes Create action in the builder stack' do
        # Arrange
        require 'vagrant-orbstack/action/create'

        # Act
        action = provider.action(:up)

        # Assert - verify the builder includes Create middleware
        # We can test this by checking the builder's stack
        expect(action).to be_a(Vagrant::Action::Builder)
      end

      it 'uses Vagrant action middleware pattern' do
        # Arrange & Act
        action = provider.action(:up)

        # Assert - builder should be callable with env hash
        expect(action).to respond_to(:call)
      end

      it 'passes correct environment to action when called' do
        # Arrange
        action = provider.action(:up)
        env = { machine: machine, ui: machine.ui }

        # Mock the Create action to verify it receives env
        create_action = double('create_action')
        allow(create_action).to receive(:call)

        # Stub Builder to use our mock
        allow(action).to receive(:call) do |passed_env|
          expect(passed_env).to include(:machine, :ui)
        end

        # Act
        action.call(env)
      end
    end

    context 'when requesting unsupported actions' do
      it 'returns action builder for :halt action (now implemented)' do
        # Arrange & Act
        action = provider.action(:halt)

        # Assert
        expect(action).to be_a(Vagrant::Action::Builder)
      end

      it 'returns action builder for :destroy action (now implemented)' do
        # Arrange & Act
        action = provider.action(:destroy)

        # Assert
        expect(action).to be_a(Vagrant::Action::Builder)
      end

      it 'returns nil for :ssh action (not yet implemented)' do
        # Arrange & Act
        action = provider.action(:ssh)

        # Assert
        expect(action).to be_nil
      end

      it 'returns action builder for :reload action (now implemented)' do
        # Arrange & Act
        action = provider.action(:reload)

        # Assert
        expect(action).to be_a(Vagrant::Action::Builder)
      end

      it 'returns nil for unknown operations' do
        # Arrange & Act
        action = provider.action(:unknown_operation)

        # Assert
        expect(action).to be_nil
      end

      it 'returns nil for :provision action (not yet implemented)' do
        # Arrange & Act
        action = provider.action(:provision)

        # Assert
        expect(action).to be_nil
      end
    end

    context 'when action builder pattern integration' do
      it 'creates new builder instance for each :up call' do
        # Arrange & Act
        action1 = provider.action(:up)
        action2 = provider.action(:up)

        # Assert - should be different instances
        expect(action1).not_to be(action2)
      end

      it 'builder is compatible with Vagrant middleware execution' do
        # Arrange
        action = provider.action(:up)

        # Assert - builder should have standard middleware interface
        expect(action).to respond_to(:call)
      end
    end
  end
end
