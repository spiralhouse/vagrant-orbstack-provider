# frozen_string_literal: true

# Test suite for VagrantPlugins::OrbStack::Util::StateCache
#
# This test verifies the StateCache utility class that provides TTL-based
# caching for machine state queries to reduce redundant CLI calls.
#
# Expected behavior:
# - Cache miss returns nil for non-existent keys
# - Cache hit returns stored value within TTL
# - Values expire after TTL seconds
# - Set stores value with timestamp
# - Invalidate removes specific key
# - invalidate_all clears entire cache
# - Multiple keys operate independently
# - Custom TTL can be configured

require 'spec_helper'

RSpec.describe 'VagrantPlugins::OrbStack::Util::StateCache' do
  describe 'class definition' do
    it 'is defined after requiring util/state_cache file' do
      expect do
        require 'vagrant-orbstack/util/state_cache'
        VagrantPlugins::OrbStack::Util::StateCache
      end.not_to raise_error
    end
  end

  describe 'initialization' do
    before do
      require 'vagrant-orbstack/util/state_cache'
    end

    let(:cache_class) { VagrantPlugins::OrbStack::Util::StateCache }

    it 'can be instantiated with default TTL' do
      expect { cache_class.new }.not_to raise_error
    end

    it 'can be instantiated with custom TTL' do
      expect { cache_class.new(ttl: 10) }.not_to raise_error
    end

    it 'stores the TTL value for later use' do
      cache = cache_class.new(ttl: 15)
      # We'll verify this through behavior tests (expiration)
      expect(cache).to be_a(cache_class)
    end
  end

  describe '#get' do
    before do
      require 'vagrant-orbstack/util/state_cache'
    end

    let(:cache_class) { VagrantPlugins::OrbStack::Util::StateCache }
    let(:cache) { cache_class.new(ttl: 5) }

    context 'when key does not exist' do
      it 'returns nil for non-existent key' do
        result = cache.get('nonexistent-key')
        expect(result).to be_nil
      end

      it 'returns nil for different non-existent keys' do
        expect(cache.get('key1')).to be_nil
        expect(cache.get('key2')).to be_nil
        expect(cache.get('key3')).to be_nil
      end
    end

    context 'when key exists within TTL' do
      it 'returns cached value for string value' do
        cache.set('test-key', 'test-value')
        result = cache.get('test-key')
        expect(result).to eq('test-value')
      end

      it 'returns cached value for symbol value' do
        cache.set('state-key', :running)
        result = cache.get('state-key')
        expect(result).to eq(:running)
      end

      it 'returns cached value for hash value' do
        metadata = { name: 'test', status: 'running' }
        cache.set('metadata-key', metadata)
        result = cache.get('metadata-key')
        expect(result).to eq(metadata)
      end

      it 'returns cached value for nil value' do
        cache.set('nil-key', nil)
        result = cache.get('nil-key')
        expect(result).to be_nil
      end
    end

    context 'when key has expired (past TTL)' do
      it 'returns nil for expired key' do
        # Mock time to control TTL expiration
        start_time = Time.at(1000)
        allow(Time).to receive(:now).and_return(start_time)

        # Set value at time 1000
        cache.set('expired-key', 'old-value')

        # Advance time past TTL (5 seconds + 1)
        expired_time = Time.at(1006)
        allow(Time).to receive(:now).and_return(expired_time)

        # Should return nil because entry expired
        result = cache.get('expired-key')
        expect(result).to be_nil
      end

      it 'returns value when exactly at TTL boundary' do
        # Test edge case: exactly at TTL expiration time
        start_time = Time.at(2000)
        allow(Time).to receive(:now).and_return(start_time)

        cache.set('boundary-key', 'boundary-value')

        # Advance time to exactly TTL (5 seconds)
        boundary_time = Time.at(2005)
        allow(Time).to receive(:now).and_return(boundary_time)

        # Should still be valid at exactly TTL seconds
        result = cache.get('boundary-key')
        expect(result).to eq('boundary-value')
      end

      it 'returns nil just after TTL boundary' do
        start_time = Time.at(3000)
        allow(Time).to receive(:now).and_return(start_time)

        cache.set('just-expired-key', 'expired-value')

        # Advance time to TTL + 0.1 seconds
        just_expired_time = Time.at(3005.1)
        allow(Time).to receive(:now).and_return(just_expired_time)

        result = cache.get('just-expired-key')
        expect(result).to be_nil
      end
    end
  end

  describe '#set' do
    before do
      require 'vagrant-orbstack/util/state_cache'
    end

    let(:cache_class) { VagrantPlugins::OrbStack::Util::StateCache }
    let(:cache) { cache_class.new(ttl: 5) }

    it 'stores value that can be retrieved' do
      cache.set('store-key', 'store-value')
      expect(cache.get('store-key')).to eq('store-value')
    end

    it 'overwrites existing value for same key' do
      cache.set('overwrite-key', 'original')
      cache.set('overwrite-key', 'updated')
      expect(cache.get('overwrite-key')).to eq('updated')
    end

    it 'stores timestamp with value for TTL calculation' do
      # Mock time to verify timestamp is captured
      set_time = Time.at(5000)
      allow(Time).to receive(:now).and_return(set_time)

      cache.set('timestamp-key', 'timestamp-value')

      # Verify value is accessible
      expect(cache.get('timestamp-key')).to eq('timestamp-value')
    end

    it 'resets TTL when value is overwritten' do
      # Set value at time 6000
      start_time = Time.at(6000)
      allow(Time).to receive(:now).and_return(start_time)
      cache.set('reset-key', 'original')

      # Advance time by 3 seconds
      middle_time = Time.at(6003)
      allow(Time).to receive(:now).and_return(middle_time)

      # Overwrite value (resets TTL)
      cache.set('reset-key', 'updated')

      # Advance time by another 4 seconds (total 7 from original)
      # but only 4 seconds from update
      late_time = Time.at(6007)
      allow(Time).to receive(:now).and_return(late_time)

      # Should still have updated value because TTL reset on overwrite
      expect(cache.get('reset-key')).to eq('updated')
    end

    it 'handles nil as a valid value' do
      cache.set('nil-value-key', nil)
      # NOTE: This is tricky - nil is both "no cache" and "cached nil"
      # Implementation should distinguish between these
      expect(cache.get('nil-value-key')).to be_nil
    end
  end

  describe '#invalidate' do
    before do
      require 'vagrant-orbstack/util/state_cache'
    end

    let(:cache_class) { VagrantPlugins::OrbStack::Util::StateCache }
    let(:cache) { cache_class.new(ttl: 5) }

    context 'when invalidating single key' do
      it 'removes specified key from cache' do
        cache.set('remove-key', 'remove-value')
        expect(cache.get('remove-key')).to eq('remove-value')

        cache.invalidate('remove-key')
        expect(cache.get('remove-key')).to be_nil
      end

      it 'does not affect other keys' do
        cache.set('keep-key-1', 'keep-value-1')
        cache.set('remove-key', 'remove-value')
        cache.set('keep-key-2', 'keep-value-2')

        cache.invalidate('remove-key')

        expect(cache.get('keep-key-1')).to eq('keep-value-1')
        expect(cache.get('keep-key-2')).to eq('keep-value-2')
        expect(cache.get('remove-key')).to be_nil
      end

      it 'handles invalidating non-existent key gracefully' do
        expect { cache.invalidate('never-existed') }.not_to raise_error
      end

      it 'allows re-setting invalidated key' do
        cache.set('cycle-key', 'original')
        cache.invalidate('cycle-key')
        cache.set('cycle-key', 'new-value')
        expect(cache.get('cycle-key')).to eq('new-value')
      end
    end
  end

  describe '#invalidate_all' do
    before do
      require 'vagrant-orbstack/util/state_cache'
    end

    let(:cache_class) { VagrantPlugins::OrbStack::Util::StateCache }
    let(:cache) { cache_class.new(ttl: 5) }

    context 'when clearing entire cache' do
      it 'removes all cached entries' do
        cache.set('key1', 'value1')
        cache.set('key2', 'value2')
        cache.set('key3', 'value3')

        cache.invalidate_all

        expect(cache.get('key1')).to be_nil
        expect(cache.get('key2')).to be_nil
        expect(cache.get('key3')).to be_nil
      end

      it 'handles clearing empty cache gracefully' do
        expect { cache.invalidate_all }.not_to raise_error
      end

      it 'allows setting values after clearing' do
        cache.set('before-key', 'before-value')
        cache.invalidate_all

        cache.set('after-key', 'after-value')
        expect(cache.get('after-key')).to eq('after-value')
        expect(cache.get('before-key')).to be_nil
      end
    end
  end

  describe 'multiple keys independence' do
    before do
      require 'vagrant-orbstack/util/state_cache'
    end

    let(:cache_class) { VagrantPlugins::OrbStack::Util::StateCache }
    let(:cache) { cache_class.new(ttl: 5) }

    it 'stores multiple keys independently' do
      cache.set('machine-1', :running)
      cache.set('machine-2', :stopped)
      cache.set('machine-3', :not_created)

      expect(cache.get('machine-1')).to eq(:running)
      expect(cache.get('machine-2')).to eq(:stopped)
      expect(cache.get('machine-3')).to eq(:not_created)
    end

    it 'expires keys independently based on their own TTL' do
      # Set machine-1 at time 7000
      time1 = Time.at(7000)
      allow(Time).to receive(:now).and_return(time1)
      cache.set('machine-1', :running)

      # Set machine-2 at time 7003 (3 seconds later)
      time2 = Time.at(7003)
      allow(Time).to receive(:now).and_return(time2)
      cache.set('machine-2', :stopped)

      # Check at time 7006 (6 seconds from machine-1, 3 seconds from machine-2)
      check_time = Time.at(7006)
      allow(Time).to receive(:now).and_return(check_time)

      # machine-1 should be expired (> 5 seconds)
      expect(cache.get('machine-1')).to be_nil
      # machine-2 should still be valid (< 5 seconds)
      expect(cache.get('machine-2')).to eq(:stopped)
    end

    it 'updates one key without affecting others' do
      cache.set('machine-1', :running)
      cache.set('machine-2', :stopped)

      cache.set('machine-1', :not_created)

      expect(cache.get('machine-1')).to eq(:not_created)
      expect(cache.get('machine-2')).to eq(:stopped)
    end
  end

  describe 'custom TTL configuration' do
    before do
      require 'vagrant-orbstack/util/state_cache'
    end

    let(:cache_class) { VagrantPlugins::OrbStack::Util::StateCache }

    it 'uses custom TTL value when specified' do
      cache = cache_class.new(ttl: 10)

      start_time = Time.at(8000)
      allow(Time).to receive(:now).and_return(start_time)
      cache.set('custom-ttl-key', 'custom-value')

      # At 8 seconds, default TTL (5s) would be expired, but custom TTL (10s) is not
      check_time = Time.at(8008)
      allow(Time).to receive(:now).and_return(check_time)

      expect(cache.get('custom-ttl-key')).to eq('custom-value')
    end

    it 'expires after custom TTL duration' do
      cache = cache_class.new(ttl: 3)

      start_time = Time.at(9000)
      allow(Time).to receive(:now).and_return(start_time)
      cache.set('short-ttl-key', 'short-value')

      # At 4 seconds, should be expired (TTL is 3 seconds)
      expired_time = Time.at(9004)
      allow(Time).to receive(:now).and_return(expired_time)

      expect(cache.get('short-ttl-key')).to be_nil
    end

    it 'uses default TTL of 5 seconds when not specified' do
      cache = cache_class.new

      start_time = Time.at(10_000)
      allow(Time).to receive(:now).and_return(start_time)
      cache.set('default-ttl-key', 'default-value')

      # At exactly 5 seconds, should still be valid
      at_ttl_time = Time.at(10_005)
      allow(Time).to receive(:now).and_return(at_ttl_time)
      expect(cache.get('default-ttl-key')).to eq('default-value')

      # Just past 5 seconds, should be expired
      past_ttl_time = Time.at(10_005.1)
      allow(Time).to receive(:now).and_return(past_ttl_time)
      expect(cache.get('default-ttl-key')).to be_nil
    end
  end

  describe 'edge cases' do
    before do
      require 'vagrant-orbstack/util/state_cache'
    end

    let(:cache_class) { VagrantPlugins::OrbStack::Util::StateCache }
    let(:cache) { cache_class.new(ttl: 5) }

    it 'handles empty string as key' do
      cache.set('', 'empty-key-value')
      expect(cache.get('')).to eq('empty-key-value')
    end

    it 'handles very long key names' do
      long_key = 'a' * 1000
      cache.set(long_key, 'long-key-value')
      expect(cache.get(long_key)).to eq('long-key-value')
    end

    it 'distinguishes between similar keys' do
      cache.set('machine', 'value1')
      cache.set('machine-1', 'value2')
      cache.set('machine_1', 'value3')

      expect(cache.get('machine')).to eq('value1')
      expect(cache.get('machine-1')).to eq('value2')
      expect(cache.get('machine_1')).to eq('value3')
    end

    it 'handles rapid set/get operations' do
      100.times do |i|
        cache.set("rapid-key-#{i}", "rapid-value-#{i}")
      end

      100.times do |i|
        expect(cache.get("rapid-key-#{i}")).to eq("rapid-value-#{i}")
      end
    end
  end
end
