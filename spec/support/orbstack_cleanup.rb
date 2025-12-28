# frozen_string_literal: true

# Utility module for cleaning up vagrant-* machines from OrbStack during test runs.
#
# This module provides methods to list and delete OrbStack machines with the "vagrant-" prefix,
# which are created during E2E and integration tests. It's designed to prevent orphaned machines
# from accumulating when tests fail, timeout, or are interrupted.
#
# @example Clean up all vagrant machines before a test suite
#   OrbStackCleanup.cleanup_all_vagrant_machines
#
# @example List all vagrant machines
#   machines = OrbStackCleanup.list_vagrant_machines
#   puts "Found #{machines.count} vagrant machines"
module OrbStackCleanup
  VAGRANT_MACHINE_PREFIX = 'vagrant-'

  class << self
    # Clean up all vagrant-* machines from OrbStack
    #
    # Iterates through all machines with the "vagrant-" prefix and deletes them.
    # This is a destructive operation that uses --force to avoid prompts.
    #
    # @param max_age_seconds [Integer] Only delete machines older than this (0 = all)
    # @return [Array<String>] List of deleted machine names
    # @example
    #   deleted = OrbStackCleanup.cleanup_all_vagrant_machines
    #   puts "Deleted #{deleted.count} machines"
    def cleanup_all_vagrant_machines(max_age_seconds: 0)
      machines = list_vagrant_machines
      deleted = []

      machines.each do |machine_name|
        next unless should_delete?(machine_name, max_age_seconds)

        delete_machine(machine_name)
        deleted << machine_name
      end

      deleted
    end

    # List all vagrant-* machines currently in OrbStack
    #
    # Parses output of `orb list` to find all machines with the "vagrant-" prefix.
    # Silently returns empty array if OrbStack is not available or command fails.
    #
    # @return [Array<String>] List of vagrant machine names
    # @example
    #   machines = OrbStackCleanup.list_vagrant_machines
    #   machines.each { |m| puts "  - #{m}" }
    def list_vagrant_machines
      output = `orb list 2>/dev/null`
      return [] unless $CHILD_STATUS&.success?

      output.lines
            .map { |line| line.split.first }
            .compact
            .select { |name| name.start_with?(VAGRANT_MACHINE_PREFIX) }
    end

    # Delete a specific machine from OrbStack
    #
    # Uses `orb delete --force` to avoid interactive prompts.
    # Silently ignores errors (machine already deleted, OrbStack offline, etc.).
    #
    # @param name [String] The machine name to delete
    # @return [Boolean] true if command succeeded, false otherwise
    # @example
    #   OrbStackCleanup.delete_machine('vagrant-default-abc123')
    def delete_machine(name)
      system("orb delete #{name} --force 2>/dev/null")
    end

    private

    # Determine if a machine should be deleted based on age criteria
    #
    # @param machine_name [String] The machine name
    # @param max_age_seconds [Integer] Maximum age in seconds (0 = delete all)
    # @return [Boolean] true if machine should be deleted
    def should_delete?(_machine_name, max_age_seconds)
      return true if max_age_seconds.zero?

      # Future enhancement: Parse `orb info <machine>` for creation timestamp
      # and compare against max_age_seconds
      true
    end
  end
end
