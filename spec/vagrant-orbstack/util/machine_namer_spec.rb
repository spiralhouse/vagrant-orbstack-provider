# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Util::MachineNamer
#
# This test suite validates the machine naming utility that generates
# unique machine names following the vagrant-<name>-<short-id> convention
# and handles collision detection/avoidance.
#
# Expected behavior:
# - Generates names in format: vagrant-<machine-name>-<short-id>
# - Short ID is 6-character hex from SecureRandom.hex(3)
# - Detects collisions by querying existing OrbStack machines
# - Retries with new ID on collision (max 3 attempts)
# - Raises error after max retries exceeded
# - Handles special characters and long machine names

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Util::MachineNamer' do
  describe 'module definition' do
    it 'is defined after requiring util/machine_namer file' do
      expect do
        require 'vagrant-orbstack/util/machine_namer'
        VagrantPlugins::OrbStack::Util::MachineNamer
      end.not_to raise_error
    end
  end

  describe '.generate' do
    before do
      require 'vagrant-orbstack/util/machine_namer'
    end

    let(:namer_class) { VagrantPlugins::OrbStack::Util::MachineNamer }

    # Mock Vagrant machine object
    let(:machine) do
      double('machine',
             name: 'default',
             provider_config: double('config'))
    end

    it 'responds to generate class method' do
      expect(namer_class).to respond_to(:generate)
    end

    # ============================================================================
    # NAME GENERATION TESTS
    # ============================================================================

    context 'when generating machine names' do
      before do
        # Mock OrbStackCLI to return no existing machines (no collision)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])

        # Mock SecureRandom to return predictable values for testing
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')
      end

      it 'generates name with correct format vagrant-<name>-<short-id>' do
        name = namer_class.generate(machine)

        expect(name).to match(/^vagrant-[a-z0-9-]+-[a-f0-9]{6}$/)
      end

      it 'uses machine name from Vagrant machine object' do
        name = namer_class.generate(machine)

        expect(name).to start_with('vagrant-default-')
      end

      it 'generates 6-character hex short ID' do
        name = namer_class.generate(machine)

        # Extract short ID (last 6 characters)
        short_id = name.split('-').last
        expect(short_id).to match(/^[a-f0-9]{6}$/)
        expect(short_id.length).to eq(6)
      end

      it 'includes machine name between vagrant prefix and short ID' do
        name = namer_class.generate(machine)

        expect(name).to eq('vagrant-default-a3b2c1')
      end

      it 'generates different IDs for each call' do
        # First call
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')
        name1 = namer_class.generate(machine)

        # Second call
        allow(SecureRandom).to receive(:hex).with(3).and_return('d4e5f6')
        name2 = namer_class.generate(machine)

        expect(name1).to eq('vagrant-default-a3b2c1')
        expect(name2).to eq('vagrant-default-d4e5f6')
        expect(name1).not_to eq(name2)
      end
    end

    # ============================================================================
    # COLLISION DETECTION TESTS
    # ============================================================================

    context 'when detecting name collisions' do
      it 'queries OrbStackCLI for existing machines' do
        # Arrange
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')
        expect(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])

        # Act
        namer_class.generate(machine)

        # Assert - expectation verified by expect().to receive()
      end

      it 'detects collision when generated name exists in OrbStack' do
        # Arrange
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1', 'd4e5f6')

        # Mock existing machine with same name as first attempt
        existing_machines = [
          { name: 'vagrant-default-a3b2c1', status: 'running' }
        ]
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return(existing_machines)

        # Act
        name = namer_class.generate(machine)

        # Assert - should retry with new ID
        expect(name).to eq('vagrant-default-d4e5f6')
      end

      it 'succeeds on first attempt when no collision' do
        # Arrange
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])

        # Act
        name = namer_class.generate(machine)

        # Assert
        expect(name).to eq('vagrant-default-a3b2c1')
        expect(SecureRandom).to have_received(:hex).once
      end

      it 'retries with new ID on collision' do
        # Arrange - first attempt collides, second succeeds
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1', 'd4e5f6')

        call_count = 0
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines) do
          call_count += 1
          if call_count == 1
            # First attempt: collision
            [{ name: 'vagrant-default-a3b2c1', status: 'running' }]
          else
            # Second attempt: no collision
            []
          end
        end

        # Act
        name = namer_class.generate(machine)

        # Assert
        expect(name).to eq('vagrant-default-d4e5f6')
        expect(SecureRandom).to have_received(:hex).twice
      end

      it 'handles multiple collisions before success' do
        # Arrange - two collisions, third attempt succeeds
        allow(SecureRandom).to receive(:hex).with(3)
          .and_return('a3b2c1', 'd4e5f6', 'g7h8i9')

        call_count = 0
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines) do
          call_count += 1
          case call_count
          when 1
            [{ name: 'vagrant-default-a3b2c1', status: 'running' }]
          when 2
            [{ name: 'vagrant-default-d4e5f6', status: 'stopped' }]
          else
            []
          end
        end

        # Act
        name = namer_class.generate(machine)

        # Assert
        expect(name).to eq('vagrant-default-g7h8i9')
        expect(SecureRandom).to have_received(:hex).exactly(3).times
      end

      it 'raises error after max retries (3) exceeded' do
        # Arrange - all 3 attempts result in collision
        allow(SecureRandom).to receive(:hex).with(3)
          .and_return('a3b2c1', 'd4e5f6', 'g7h8i9')

        # All attempts collide
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([
                        { name: 'vagrant-default-a3b2c1', status: 'running' },
                        { name: 'vagrant-default-d4e5f6', status: 'stopped' },
                        { name: 'vagrant-default-g7h8i9', status: 'running' }
                      ])

        # Act & Assert
        expect { namer_class.generate(machine) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::MachineNameCollisionError,
          /Failed to generate unique machine name after 3 attempts/
        )
      end

      it 'includes machine name in error message after max retries' do
        # Arrange
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1', 'd4e5f6', 'g7h8i9')
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([
                        { name: 'vagrant-default-a3b2c1', status: 'running' },
                        { name: 'vagrant-default-d4e5f6', status: 'running' },
                        { name: 'vagrant-default-g7h8i9', status: 'running' }
                      ])

        # Act & Assert
        expect { namer_class.generate(machine) }.to raise_error(
          an_instance_of(VagrantPlugins::OrbStack::Errors::MachineNameCollisionError)
            .and(having_attributes(message: include('default')))
        )
      end
    end

    # ============================================================================
    # EDGE CASE TESTS
    # ============================================================================

    context 'when handling edge cases' do
      before do
        # Mock no collisions for edge case tests
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_return([])
      end

      it 'handles machine names with hyphens' do
        # Arrange
        hyphenated_machine = double('machine',
                                    name: 'web-server-1',
                                    provider_config: double('config'))
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Act
        name = namer_class.generate(hyphenated_machine)

        # Assert
        expect(name).to eq('vagrant-web-server-1-a3b2c1')
      end

      it 'sanitizes machine names with underscores to hyphens' do
        # Arrange
        underscore_machine = double('machine',
                                    name: 'web_server',
                                    provider_config: double('config'))
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Act
        name = namer_class.generate(underscore_machine)

        # Assert
        expect(name).to eq('vagrant-web-server-a3b2c1')
      end

      it 'converts machine names to lowercase' do
        # Arrange
        uppercase_machine = double('machine',
                                   name: 'WEB-SERVER',
                                   provider_config: double('config'))
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Act
        name = namer_class.generate(uppercase_machine)

        # Assert
        expect(name).to eq('vagrant-web-server-a3b2c1')
      end

      it 'truncates very long machine names to prevent OrbStack limits' do
        # Arrange
        # OrbStack machine names have practical limits (typically 63 chars for DNS)
        long_name = 'very-long-machine-name-that-exceeds-reasonable-length-limits-and-should-be-truncated'
        long_machine = double('machine',
                              name: long_name,
                              provider_config: double('config'))
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Act
        name = namer_class.generate(long_machine)

        # Assert
        # Total length should be <= 63 chars (vagrant- prefix + truncated name + - + 6 char ID)
        expect(name.length).to be <= 63
        expect(name).to start_with('vagrant-very-long-machine-name')
        expect(name).to end_with('-a3b2c1')
      end

      it 'handles nil machine name by using "default"' do
        # Arrange
        nil_name_machine = double('machine',
                                  name: nil,
                                  provider_config: double('config'))
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Act
        name = namer_class.generate(nil_name_machine)

        # Assert
        expect(name).to eq('vagrant-default-a3b2c1')
      end

      it 'handles empty machine name by using "default"' do
        # Arrange
        empty_name_machine = double('machine',
                                    name: '',
                                    provider_config: double('config'))
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Act
        name = namer_class.generate(empty_name_machine)

        # Assert
        expect(name).to eq('vagrant-default-a3b2c1')
      end

      it 'removes special characters from machine names' do
        # Arrange
        special_chars_machine = double('machine',
                                       name: 'web@server!test#box',
                                       provider_config: double('config'))
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Act
        name = namer_class.generate(special_chars_machine)

        # Assert - special chars should be removed or replaced
        expect(name).to match(/^vagrant-[a-z0-9-]+-[a-f0-9]{6}$/)
        expect(name).to eq('vagrant-webservertestbox-a3b2c1')
      end

      it 'handles machine names with leading/trailing whitespace' do
        # Arrange
        whitespace_machine = double('machine',
                                    name: '  web-server  ',
                                    provider_config: double('config'))
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Act
        name = namer_class.generate(whitespace_machine)

        # Assert
        expect(name).to eq('vagrant-web-server-a3b2c1')
      end

      it 'handles machine names with consecutive hyphens' do
        # Arrange
        consecutive_hyphens_machine = double('machine',
                                             name: 'web--server',
                                             provider_config: double('config'))
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')

        # Act
        name = namer_class.generate(consecutive_hyphens_machine)

        # Assert - consecutive hyphens should be collapsed
        expect(name).to eq('vagrant-web-server-a3b2c1')
      end
    end

    # ============================================================================
    # ERROR HANDLING TESTS
    # ============================================================================

    context 'when handling OrbStackCLI errors' do
      it 'propagates OrbStackCLI errors when querying existing machines' do
        # Arrange
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_raise(VagrantPlugins::OrbStack::Errors::OrbStackNotInstalledError)

        # Act & Assert
        expect { namer_class.generate(machine) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::OrbStackNotInstalledError
        )
      end

      it 'handles timeout errors when querying OrbStack' do
        # Arrange
        allow(SecureRandom).to receive(:hex).with(3).and_return('a3b2c1')
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI).to receive(:list_machines)
          .and_raise(VagrantPlugins::OrbStack::Errors::CommandTimeoutError)

        # Act & Assert
        expect { namer_class.generate(machine) }.to raise_error(
          VagrantPlugins::OrbStack::Errors::CommandTimeoutError
        )
      end
    end
  end
end
