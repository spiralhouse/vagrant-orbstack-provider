# frozen_string_literal: true

module VagrantPlugins
  module OrbStack
    module Util
      # TTL-based cache utility for machine state queries.
      #
      # This class provides a simple time-to-live (TTL) cache to reduce redundant
      # CLI calls when querying machine state. State queries are cached with a
      # configurable TTL (default 5 seconds), and automatically expire when the
      # TTL is exceeded.
      #
      # The cache is designed for Vagrant's single-threaded environment and does
      # not implement thread-safety mechanisms.
      #
      # @example Basic usage with default TTL
      #   cache = StateCache.new
      #   cache.set('machine-id', state)
      #   cached_state = cache.get('machine-id')  # Returns state
      #
      # @example Custom TTL
      #   cache = StateCache.new(ttl: 10)  # 10-second cache
      #   cache.set('key', 'value')
      #   # 11 seconds later...
      #   cache.get('key')  # Returns nil (expired)
      #
      # @example Cache invalidation
      #   cache.invalidate('key')       # Remove specific key
      #   cache.invalidate_all          # Clear entire cache
      class StateCache
        # Default TTL for cached entries (in seconds)
        DEFAULT_TTL = 5

        # Initialize a new state cache.
        #
        # @param ttl [Integer] Time-to-live for cached entries in seconds (default: 5)
        # @api public
        def initialize(ttl: DEFAULT_TTL)
          @ttl = ttl
          @cache = {}
        end

        # Retrieve a cached value.
        #
        # Returns the cached value if it exists and has not expired. Returns nil
        # if the key doesn't exist or if the cached entry has exceeded its TTL.
        #
        # @param key [String] The cache key
        # @return [Object, nil] The cached value if valid, nil if missing or expired
        # @api public
        def get(key)
          entry = @cache[key]
          return nil unless entry

          # Check if entry has expired
          if Time.now - entry[:timestamp] > @ttl
            # Entry expired, remove it and return nil
            @cache.delete(key)
            return nil
          end

          entry[:value]
        end

        # Store a value in the cache.
        #
        # Stores the value with the current timestamp. If the key already exists,
        # its value and timestamp are overwritten.
        #
        # @param key [String] The cache key
        # @param value [Object] The value to cache (can be any object, including nil)
        # @return [void]
        # @api public
        def set(key, value)
          @cache[key] = {
            value: value,
            timestamp: Time.now
          }
        end

        # Invalidate a specific cache entry.
        #
        # Removes the specified key from the cache. This is a no-op if the key
        # doesn't exist.
        #
        # @param key [String] The cache key to remove
        # @return [void]
        # @api public
        def invalidate(key)
          @cache.delete(key)
        end

        # Clear all cache entries.
        #
        # Removes all cached entries. This is useful when you need to ensure
        # fresh data is retrieved on the next query.
        #
        # @return [void]
        # @api public
        def invalidate_all
          @cache.clear
        end
      end
    end
  end
end
