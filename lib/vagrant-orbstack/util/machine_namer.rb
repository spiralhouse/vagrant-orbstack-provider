# frozen_string_literal: true

require 'securerandom'
require_relative 'orbstack_cli'
require_relative '../errors'

module VagrantPlugins
  module OrbStack
    module Util
      # Utility class for generating unique machine names with collision avoidance
      #
      # Generates machine names in the format: vagrant-<sanitized-name>-<short-id>
      # where short-id is a 6-character random hex string. Implements collision
      # detection and automatic retry with new IDs.
      #
      # @example Generate a unique machine name
      #   machine = double('machine', name: 'web_server')
      #   name = MachineNamer.generate(machine)
      #   # => "vagrant-web-server-a3b2c1"
      #
      # @example Collision handling
      #   # If "vagrant-default-a3b2c1" exists, generates new ID automatically
      #   name = MachineNamer.generate(machine)
      #   # => "vagrant-default-d4e5f6" (different ID)
      #
      # @api public
      class MachineNamer
        # Maximum number of retry attempts for collision avoidance
        MAX_RETRIES = 3

        # Maximum machine name length (DNS hostname limit)
        MAX_NAME_LENGTH = 63

        # Generate a unique machine name with collision avoidance.
        #
        # Creates a machine name in the format vagrant-<name>-<id> where:
        # - name is sanitized from machine.name (lowercase, hyphens, alphanumeric)
        # - id is a 6-character random hex string
        #
        # If a collision is detected (name already exists in OrbStack), retries
        # with a new random ID up to MAX_RETRIES times.
        #
        # @param machine [Vagrant::Machine] The machine object with name attribute
        # @return [String] A unique machine name
        # @raise [MachineNameCollisionError] If all retry attempts are exhausted
        # @raise [OrbStackNotInstalled] If OrbStack CLI is not available
        # @raise [CommandTimeoutError] If OrbStack CLI times out
        # @api public
        def self.generate(machine)
          machine_name = machine.name.to_s
          sanitized = sanitize_name(machine_name)

          MAX_RETRIES.times do
            short_id = SecureRandom.hex(3)
            candidate = "vagrant-#{sanitized}-#{short_id}"

            return candidate unless check_collision?(candidate)
          end

          # All retries exhausted - raise error
          raise MachineNameCollisionError,
                "Failed to generate unique machine name after #{MAX_RETRIES} attempts (machine: #{machine_name})"
        end

        # Sanitize a machine name for use in hostname.
        #
        # Applies the following transformations:
        # - Convert to lowercase
        # - Replace underscores with hyphens
        # - Remove all characters except alphanumeric and hyphens
        # - Strip leading/trailing whitespace
        # - Collapse consecutive hyphens to single hyphen
        # - Truncate to fit within MAX_NAME_LENGTH minus prefix/suffix space
        # - Default to "default" if result is empty
        #
        # @param name [String, nil] The name to sanitize
        # @return [String] The sanitized name
        # @api private
        class << self
          private

          # Method length acceptable: Each transformation step is clear and well-documented.
          # Combining steps would reduce readability.
          # rubocop:disable Metrics/MethodLength
          def sanitize_name(name)
            # Handle nil or empty input → default
            return 'default' if name.nil? || name.strip.empty?

            # Apply sanitization rules:
            # 1. Strip whitespace
            # 2. Convert to lowercase
            # 3. Replace underscores with hyphens (DNS-safe)
            # 4. Remove non-alphanumeric (except hyphens)
            # 5. Collapse consecutive hyphens
            # 6. Remove leading/trailing hyphens
            sanitized = name.to_s
                            .strip           # Rule 1
                            .downcase        # Rule 2
                            .gsub('_', '-')  # Rule 3
                            .gsub(/[^a-z0-9-]/, '')  # Rule 4
                            .gsub(/-+/, '-')         # Rule 5
                            .gsub(/^-|-$/, '')       # Rule 6

            return 'default' if sanitized.empty?

            # DNS limit (63) - "vagrant-" (8) - "-XXXXXX" (7) = 48 max
            max_length = MAX_NAME_LENGTH - 15
            sanitized[0...max_length]
          end
          # rubocop:enable Metrics/MethodLength

          # Check if a machine name already exists in OrbStack.
          #
          # Queries OrbStack CLI for list of existing machines and checks
          # if the candidate name is already in use.
          #
          # @param name [String] The candidate name to check
          # @return [Boolean] true if collision detected, false otherwise
          # @raise [OrbStackNotInstalled] If OrbStack CLI is not available
          # @raise [CommandTimeoutError] If OrbStack CLI times out
          # @api private
          def check_collision?(name)
            machines = OrbStackCLI.list_machines
            machines.any? { |m| m[:name] == name }
          end
        end
      end
    end
  end
end
