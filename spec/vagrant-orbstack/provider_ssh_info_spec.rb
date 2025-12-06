# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Provider#ssh_info
#
# This test verifies that the Provider#ssh_info method correctly returns
# SSH connection parameters for Vagrant to connect to OrbStack machines.
#
# Expected behavior:
# - Returns hash with :host, :port, :username, :forward_agent
# - Host obtained from OrbStack machine info (ip4 field)
# - Port defaults to 22
# - Username uses configured ssh_username or falls back to OrbStack default_username
# - forward_agent uses configured value (default false)
# - Returns nil when machine state is :not_created or :stopped
# - Raises SSHNotReady when IP address is missing but machine is running
#
# Reference: SPI-1225 - Provider#ssh_info implementation

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Provider#ssh_info' do
  # Mock Vagrant machine object for testing
  let(:ui) do
    double('ui').tap do |ui|
      allow(ui).to receive(:warn)
      allow(ui).to receive(:error)
    end
  end

  let(:provider_config) do
    double('config').tap do |config|
      allow(config).to receive(:ssh_username).and_return(nil)
      allow(config).to receive(:forward_agent).and_return(false)
    end
  end

  let(:machine) do
    double('machine',
           name: 'default',
           provider_config: provider_config,
           data_dir: Pathname.new('/tmp/vagrant-test'),
           ui: ui,
           id: 'test-machine-id')
  end

  let(:provider) do
    require 'vagrant-orbstack/provider'
    VagrantPlugins::OrbStack::Provider.new(machine)
  end

  # ============================================================================
  # PROVIDER#SSH_INFO TESTS (SPI-1225)
  # ============================================================================
  #
  # These tests verify that the Provider#ssh_info method correctly returns
  # SSH connection parameters based on OrbStack machine state and configuration.
  #
  # Reference: SPI-1225 - Provider#ssh_info implementation
  # ============================================================================

  describe '#ssh_info' do
    context 'when machine state is :not_created' do
      it 'returns nil' do
        # Arrange
        not_created_state = Vagrant::MachineState.new(
          :not_created,
          'not created',
          'Machine does not exist in OrbStack'
        )
        allow(provider).to receive(:state).and_return(not_created_state)

        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_nil
      end
    end

    context 'when machine state is :stopped' do
      it 'returns nil' do
        # Arrange
        stopped_state = Vagrant::MachineState.new(
          :stopped,
          'stopped',
          'Machine is stopped'
        )
        allow(provider).to receive(:state).and_return(stopped_state)

        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_nil
      end
    end

    context 'when machine is running and has IP address' do
      let(:running_state) do
        Vagrant::MachineState.new(
          :running,
          'running',
          'Machine is running in OrbStack'
        )
      end

      let(:machine_info) do
        {
          'record' => {
            'state' => 'running',
            'config' => {
              'default_username' => 'orbstack'
            }
          },
          'ip4' => '192.168.139.89'
        }
      end

      before do
        allow(provider).to receive(:state).and_return(running_state)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI)
          .to receive(:machine_info)
          .with('test-machine-id')
          .and_return(machine_info)
      end

      it 'returns hash with :host from OrbStack ip4 field' do
        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_a(Hash)
        expect(result[:host]).to eq('192.168.139.89')
      end

      it 'returns hash with :port as 22' do
        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_a(Hash)
        expect(result[:port]).to eq(22)
      end

      context 'when ssh_username is configured' do
        before do
          allow(provider_config).to receive(:ssh_username).and_return('vagrant')
        end

        it 'returns hash with :username from config' do
          # Act
          result = provider.ssh_info

          # Assert
          expect(result).to be_a(Hash)
          expect(result[:username]).to eq('vagrant')
        end
      end

      context 'when ssh_username is not configured' do
        before do
          allow(provider_config).to receive(:ssh_username).and_return(nil)
        end

        it 'returns hash with :username from OrbStack default_username' do
          # Act
          result = provider.ssh_info

          # Assert
          expect(result).to be_a(Hash)
          expect(result[:username]).to eq('orbstack')
        end
      end

      context 'when forward_agent is configured as true' do
        before do
          allow(provider_config).to receive(:forward_agent).and_return(true)
        end

        it 'returns hash with :forward_agent as true' do
          # Act
          result = provider.ssh_info

          # Assert
          expect(result).to be_a(Hash)
          expect(result[:forward_agent]).to eq(true)
        end
      end

      context 'when forward_agent is configured as false' do
        before do
          allow(provider_config).to receive(:forward_agent).and_return(false)
        end

        it 'returns hash with :forward_agent as false' do
          # Act
          result = provider.ssh_info

          # Assert
          expect(result).to be_a(Hash)
          expect(result[:forward_agent]).to eq(false)
        end
      end
    end

    context 'when machine is running but ip4 is nil' do
      let(:running_state) do
        Vagrant::MachineState.new(
          :running,
          'running',
          'Machine is running in OrbStack'
        )
      end

      let(:machine_info_no_ip) do
        {
          'record' => {
            'state' => 'running',
            'config' => {
              'default_username' => 'orbstack'
            }
          },
          'ip4' => nil
        }
      end

      before do
        allow(provider).to receive(:state).and_return(running_state)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI)
          .to receive(:machine_info)
          .with('test-machine-id')
          .and_return(machine_info_no_ip)
      end

      it 'raises SSHNotReady error' do
        # Act & Assert
        expect { provider.ssh_info }.to raise_error(VagrantPlugins::OrbStack::SSHNotReady)
      end
    end

    context 'when machine is running but ip4 is empty string' do
      let(:running_state) do
        Vagrant::MachineState.new(
          :running,
          'running',
          'Machine is running in OrbStack'
        )
      end

      let(:machine_info_empty_ip) do
        {
          'record' => {
            'state' => 'running',
            'config' => {
              'default_username' => 'orbstack'
            }
          },
          'ip4' => ''
        }
      end

      before do
        allow(provider).to receive(:state).and_return(running_state)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI)
          .to receive(:machine_info)
          .with('test-machine-id')
          .and_return(machine_info_empty_ip)
      end

      it 'raises SSHNotReady error' do
        # Act & Assert
        expect { provider.ssh_info }.to raise_error(VagrantPlugins::OrbStack::SSHNotReady)
      end
    end

    context 'when OrbStack CLI machine_info fails' do
      let(:running_state) do
        Vagrant::MachineState.new(
          :running,
          'running',
          'Machine is running in OrbStack'
        )
      end

      before do
        allow(provider).to receive(:state).and_return(running_state)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI)
          .to receive(:machine_info)
          .with('test-machine-id')
          .and_return(nil)
      end

      it 'returns nil when machine_info returns nil' do
        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_nil
      end
    end

    context 'when OrbStack CLI machine_info raises error' do
      let(:running_state) do
        Vagrant::MachineState.new(
          :running,
          'running',
          'Machine is running in OrbStack'
        )
      end

      before do
        allow(provider).to receive(:state).and_return(running_state)
        allow(VagrantPlugins::OrbStack::Util::OrbStackCLI)
          .to receive(:machine_info)
          .with('test-machine-id')
          .and_raise(StandardError, 'CLI command failed')
      end

      it 'returns nil when machine_info raises error' do
        # Act
        result = provider.ssh_info

        # Assert
        expect(result).to be_nil
      end
    end
  end
end
