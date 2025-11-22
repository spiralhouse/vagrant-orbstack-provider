# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Provider state management
#
# This test verifies the Provider#state method which queries OrbStack CLI
# for machine state and caches results to reduce redundant CLI calls.
#
# Expected behavior:
# - Returns Vagrant::MachineState object with correct state_id
# - Maps OrbStack states to Vagrant states correctly
# - Caches state queries with 5-second TTL
# - Avoids redundant CLI calls on cache hit
# - Handles machine not found gracefully
# - Handles CLI errors gracefully
# - Provides meaningful state descriptions

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Provider#state' do
  let(:machine) do
    ui = double('ui')
    allow(ui).to receive(:warn)
    allow(ui).to receive(:error)

    double('machine',
           name: 'default',
           id: 'vagrant-test-machine',
           provider_config: double('config'),
           data_dir: Pathname.new('/tmp/vagrant-test'),
           ui: ui)
  end

  let(:provider) do
    require 'vagrant-orbstack/provider'
    require 'vagrant-orbstack/util/orbstack_cli'
    VagrantPlugins::OrbStack::Provider.new(machine)
  end

  let(:cli_class) { VagrantPlugins::OrbStack::Util::OrbStackCLI }

  before do
    # Ensure provider is loaded
    require 'vagrant-orbstack/provider'
    require 'vagrant-orbstack/util/orbstack_cli'
  end

  describe 'state initialization' do
    it 'initializes state cache on first call' do
      # Mock CLI to return empty list (machine not found)
      allow(cli_class).to receive(:list_machines).and_return([])

      state = provider.state

      # Should return a MachineState object
      expect(state).to be_a(Vagrant::MachineState)
    end
  end

  describe 'state mapping from OrbStack to Vagrant' do
    context 'when machine is running' do
      before do
        # Mock OrbStack CLI to return running machine
        allow(cli_class).to receive(:list_machines).and_return([
                                                                 { name: 'vagrant-test-machine', status: 'running' }
                                                               ])
      end

      it 'returns :running state' do
        state = provider.state
        expect(state.id).to eq(:running)
      end

      it 'returns MachineState object' do
        state = provider.state
        expect(state).to be_a(Vagrant::MachineState)
      end

      it 'provides short description for running state' do
        state = provider.state
        expect(state.short_description).to be_a(String)
        expect(state.short_description.downcase).to include('running')
      end

      it 'provides long description for running state' do
        state = provider.state
        expect(state.long_description).to be_a(String)
        expect(state.long_description).not_to be_empty
      end
    end

    context 'when machine is stopped' do
      before do
        # Mock OrbStack CLI to return stopped machine
        allow(cli_class).to receive(:list_machines).and_return([
                                                                 { name: 'vagrant-test-machine', status: 'stopped' }
                                                               ])
      end

      it 'returns :stopped state' do
        state = provider.state
        expect(state.id).to eq(:stopped)
      end

      it 'returns MachineState object' do
        state = provider.state
        expect(state).to be_a(Vagrant::MachineState)
      end

      it 'provides short description for stopped state' do
        state = provider.state
        expect(state.short_description).to be_a(String)
        expect(state.short_description.downcase).to include('stopped')
      end

      it 'provides long description for stopped state' do
        state = provider.state
        expect(state.long_description).to be_a(String)
        expect(state.long_description).not_to be_empty
      end
    end

    context 'when machine does not exist' do
      before do
        # Mock OrbStack CLI to return empty list (no machines)
        allow(cli_class).to receive(:list_machines).and_return([])
      end

      it 'returns :not_created state' do
        state = provider.state
        expect(state.id).to eq(:not_created)
      end

      it 'returns MachineState object' do
        state = provider.state
        expect(state).to be_a(Vagrant::MachineState)
      end

      it 'provides short description for not_created state' do
        state = provider.state
        expect(state.short_description).to be_a(String)
        expect(state.short_description.downcase).to match(/not created|does not exist/)
      end

      it 'provides long description for not_created state' do
        state = provider.state
        expect(state.long_description).to be_a(String)
        expect(state.long_description).not_to be_empty
      end
    end

    context 'when machine ID is nil' do
      let(:machine_no_id) do
        ui = double('ui')
        allow(ui).to receive(:warn)
        allow(ui).to receive(:error)

        double('machine',
               name: 'default',
               id: nil,
               provider_config: double('config'),
               data_dir: Pathname.new('/tmp/vagrant-test'),
               ui: ui)
      end

      let(:provider_no_id) do
        VagrantPlugins::OrbStack::Provider.new(machine_no_id)
      end

      it 'returns :not_created state without querying CLI' do
        # Should not call list_machines when ID is nil
        expect(cli_class).not_to receive(:list_machines)

        state = provider_no_id.state
        expect(state.id).to eq(:not_created)
      end
    end
  end

  describe 'state caching behavior' do
    context 'when state is queried multiple times' do
      before do
        # Mock OrbStack CLI to return running machine
        allow(cli_class).to receive(:list_machines).and_return([
                                                                 { name: 'vagrant-test-machine', status: 'running' }
                                                               ])
      end

      it 'calls OrbStack CLI on first query' do
        # Expect CLI to be called exactly once
        expect(cli_class).to receive(:list_machines).once.and_return([
                                                                       { name: 'vagrant-test-machine',
                                                                         status: 'running' }
                                                                     ])

        provider.state
      end

      it 'uses cache on second query within TTL' do
        # First call should hit CLI
        expect(cli_class).to receive(:list_machines).once.and_return([
                                                                       { name: 'vagrant-test-machine',
                                                                         status: 'running' }
                                                                     ])

        state1 = provider.state
        state2 = provider.state # Should use cache, not call CLI again

        expect(state1.id).to eq(:running)
        expect(state2.id).to eq(:running)
      end

      it 'does not call CLI on subsequent queries within TTL' do
        # Set up mock to track call count
        call_count = 0
        allow(cli_class).to receive(:list_machines) do
          call_count += 1
          [{ name: 'vagrant-test-machine', status: 'running' }]
        end

        # Call state multiple times
        provider.state
        provider.state
        provider.state

        # Should only call CLI once
        expect(call_count).to eq(1)
      end
    end

    context 'when cache expires after TTL' do
      it 'calls CLI again after cache expiration' do
        # Mock time for TTL testing
        start_time = Time.at(20_000)
        allow(Time).to receive(:now).and_return(start_time)

        # First call at time 20000
        expect(cli_class).to receive(:list_machines).and_return([
                                                                  { name: 'vagrant-test-machine', status: 'running' }
                                                                ])
        state1 = provider.state
        expect(state1.id).to eq(:running)

        # Advance time past TTL (5 seconds + 1)
        expired_time = Time.at(20_006)
        allow(Time).to receive(:now).and_return(expired_time)

        # Second call should query CLI again
        expect(cli_class).to receive(:list_machines).and_return([
                                                                  { name: 'vagrant-test-machine', status: 'stopped' }
                                                                ])
        state2 = provider.state
        expect(state2.id).to eq(:stopped)
      end
    end

    context 'when cache is invalidated manually' do
      it 'calls CLI on next query after invalidation' do
        # First call
        expect(cli_class).to receive(:list_machines).and_return([
                                                                  { name: 'vagrant-test-machine', status: 'running' }
                                                                ])
        state1 = provider.state
        expect(state1.id).to eq(:running)

        # Invalidate cache (assuming provider exposes invalidate_state_cache method)
        # This tests that provider can invalidate cache when needed
        provider.invalidate_state_cache

        # Next call should query CLI again
        expect(cli_class).to receive(:list_machines).and_return([
                                                                  { name: 'vagrant-test-machine', status: 'stopped' }
                                                                ])
        state2 = provider.state
        expect(state2.id).to eq(:stopped)
      end
    end
  end

  describe 'CLI error handling' do
    context 'when OrbStack CLI is not available' do
      before do
        # Mock CLI to simulate command failure
        allow(cli_class).to receive(:list_machines).and_raise(StandardError, 'Command not found')
      end

      it 'returns :not_created state gracefully' do
        state = provider.state
        expect(state.id).to eq(:not_created)
      end

      it 'does not raise error' do
        expect { provider.state }.not_to raise_error
      end

      it 'logs warning to user' do
        expect(machine.ui).to receive(:warn).with(/OrbStack.*error/i)
        provider.state
      end
    end

    context 'when OrbStack CLI returns empty list' do
      before do
        allow(cli_class).to receive(:list_machines).and_return([])
      end

      it 'returns :not_created state' do
        state = provider.state
        expect(state.id).to eq(:not_created)
      end
    end

    context 'when OrbStack CLI times out' do
      before do
        require 'vagrant-orbstack/errors'
        allow(cli_class).to receive(:list_machines).and_raise(
          VagrantPlugins::OrbStack::CommandTimeoutError, 'Command timed out'
        )
      end

      it 'returns :not_created state gracefully' do
        state = provider.state
        expect(state.id).to eq(:not_created)
      end

      it 'logs timeout warning to user' do
        expect(machine.ui).to receive(:warn).with(/timeout/i)
        provider.state
      end
    end

    context 'when machine list contains other machines' do
      before do
        # Mock CLI to return list with different machines
        allow(cli_class).to receive(:list_machines).and_return([
                                                                 { name: 'other-machine-1', status: 'running' },
                                                                 { name: 'other-machine-2', status: 'stopped' }
                                                               ])
      end

      it 'returns :not_created when machine not in list' do
        state = provider.state
        expect(state.id).to eq(:not_created)
      end
    end
  end

  describe 'state descriptions' do
    it 'provides distinct descriptions for each state' do
      states = {}

      # Collect descriptions for :running state
      allow(cli_class).to receive(:list_machines).and_return([
                                                               { name: 'vagrant-test-machine', status: 'running' }
                                                             ])
      running_state = provider.state
      states[:running] = {
        short: running_state.short_description,
        long: running_state.long_description
      }

      # Reset cache for next test
      provider.invalidate_state_cache

      # Collect descriptions for :stopped state
      allow(cli_class).to receive(:list_machines).and_return([
                                                               { name: 'vagrant-test-machine', status: 'stopped' }
                                                             ])
      stopped_state = provider.state
      states[:stopped] = {
        short: stopped_state.short_description,
        long: stopped_state.long_description
      }

      # Reset cache for next test
      provider.invalidate_state_cache

      # Collect descriptions for :not_created state
      allow(cli_class).to receive(:list_machines).and_return([])
      not_created_state = provider.state
      states[:not_created] = {
        short: not_created_state.short_description,
        long: not_created_state.long_description
      }

      # Verify each state has unique descriptions
      expect(states[:running][:short]).not_to eq(states[:stopped][:short])
      expect(states[:running][:short]).not_to eq(states[:not_created][:short])
      expect(states[:stopped][:short]).not_to eq(states[:not_created][:short])
    end
  end

  describe 'integration with machine lifecycle' do
    context 'when machine transitions from not_created to running' do
      it 'reflects state change after cache expiration' do
        # Initially machine doesn't exist
        allow(cli_class).to receive(:list_machines).and_return([])
        state1 = provider.state
        expect(state1.id).to eq(:not_created)

        # Invalidate cache to simulate time passing or manual refresh
        provider.invalidate_state_cache

        # Now machine exists and is running
        allow(cli_class).to receive(:list_machines).and_return([
                                                                 { name: 'vagrant-test-machine', status: 'running' }
                                                               ])
        state2 = provider.state
        expect(state2.id).to eq(:running)
      end
    end

    context 'when machine transitions from running to stopped' do
      it 'reflects state change after cache expiration' do
        # Initially machine is running
        allow(cli_class).to receive(:list_machines).and_return([
                                                                 { name: 'vagrant-test-machine', status: 'running' }
                                                               ])
        state1 = provider.state
        expect(state1.id).to eq(:running)

        # Invalidate cache
        provider.invalidate_state_cache

        # Now machine is stopped
        allow(cli_class).to receive(:list_machines).and_return([
                                                                 { name: 'vagrant-test-machine', status: 'stopped' }
                                                               ])
        state2 = provider.state
        expect(state2.id).to eq(:stopped)
      end
    end
  end

  describe 'edge cases' do
    context 'when machine name contains special characters' do
      let(:special_machine) do
        ui = double('ui')
        allow(ui).to receive(:warn)
        allow(ui).to receive(:error)

        double('machine',
               name: 'my-test_machine.v2',
               id: 'vagrant-my-test_machine.v2-abc123',
               provider_config: double('config'),
               data_dir: Pathname.new('/tmp/vagrant-test'),
               ui: ui)
      end

      let(:special_provider) do
        VagrantPlugins::OrbStack::Provider.new(special_machine)
      end

      it 'queries for correct machine name' do
        expect(cli_class).to receive(:list_machines).and_return([
                                                                  { name: 'vagrant-my-test_machine.v2-abc123',
                                                                    status: 'running' }
                                                                ])
        state = special_provider.state
        expect(state.id).to eq(:running)
      end
    end

    context 'when OrbStack returns unexpected state' do
      before do
        # Mock CLI to return unrecognized state
        allow(cli_class).to receive(:list_machines).and_return([
                                                                 { name: 'vagrant-test-machine',
                                                                   status: 'unknown-state' }
                                                               ])
      end

      it 'handles unknown state gracefully' do
        # Should not raise error
        expect { provider.state }.not_to raise_error
      end

      it 'returns sensible default state for unknown status' do
        state = provider.state
        # Implementation should decide: treat as :not_created or create :unknown state
        expect(%i[not_created unknown]).to include(state.id)
      end
    end
  end
end
