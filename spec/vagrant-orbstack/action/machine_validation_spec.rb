# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/vagrant-orbstack/action/machine_validation'

RSpec.describe 'MachineValidation module' do
  # Create a test class that includes the module
  let(:test_class) do
    Class.new do
      include VagrantPlugins::OrbStack::Action::MachineValidation
    end
  end

  let(:test_instance) { test_class.new }
  let(:machine) { double('machine') }

  describe '#validate_machine_id!' do
    context 'when machine has valid ID' do
      it 'returns the machine ID' do
        allow(machine).to receive(:id).and_return('test-machine-123')

        result = test_instance.validate_machine_id!(machine, 'test')

        expect(result).to eq('test-machine-123')
      end
    end

    context 'when machine ID is nil' do
      it 'raises ArgumentError with appropriate message' do
        allow(machine).to receive(:id).and_return(nil)

        expect do
          test_instance.validate_machine_id!(machine, 'destroy')
        end.to raise_error(ArgumentError, /Cannot destroy machine: machine ID is nil or empty/)
      end
    end

    context 'when machine ID is empty string' do
      it 'raises ArgumentError with appropriate message' do
        allow(machine).to receive(:id).and_return('')

        expect do
          test_instance.validate_machine_id!(machine, 'halt')
        end.to raise_error(ArgumentError, /Cannot halt machine: machine ID is nil or empty/)
      end
    end

    context 'error message includes action name' do
      it 'uses the provided action name in error message' do
        allow(machine).to receive(:id).and_return(nil)

        expect do
          test_instance.validate_machine_id!(machine, 'start')
        end.to raise_error(ArgumentError, /Cannot start machine/)
      end
    end
  end
end
