# frozen_string_literal: true

require 'json'
require 'fileutils'

module VagrantPlugins
  module OrbStack
    # Vagrant provider implementation for OrbStack.
    #
    # This class implements the Vagrant provider interface, delegating
    # machine lifecycle operations to OrbStack via CLI commands.
    #
    # @api public
    class Provider < Vagrant.plugin('2', :provider)
      # Initialize the provider with a machine instance.
      #
      # @param [Vagrant::Machine] machine The machine this provider is for
      # @api public
      def initialize(machine)
        @machine = machine
        @logger = Log4r::Logger.new('vagrant_orbstack::provider')
      end

      # Return action middleware for requested operation.
      #
      # @param [Symbol] _name The action name
      # @return [Object, nil] Action middleware (currently stubbed)
      # @api public
      # @todo Implement action middleware (tracked in future stories)
      def action(_name)
        # Stub for now - will be implemented in future stories
        nil
      end

      # Provide SSH connection information for the machine.
      #
      # @return [Hash, nil] SSH connection parameters (currently stubbed)
      # @api public
      # @todo Implement SSH info retrieval (tracked in future stories)
      def ssh_info
        # Stub for now - will be implemented in future stories
        nil
      end

      # Return current machine state.
      #
      # @return [Vagrant::MachineState] Current state of the machine
      # @api public
      # @todo Implement actual state detection (tracked in future stories)
      def state
        # Stub for now - will be implemented in future stories
        Vagrant::MachineState.new(:not_created, 'not created', 'Machine does not exist')
      end

      # Human-readable provider description.
      #
      # @return [String] Provider name
      # @api public
      def to_s
        'OrbStack'
      end

      # Callback invoked when the machine ID changes.
      #
      # Persists the new machine ID to the data directory for retrieval
      # in future Vagrant sessions. This is called by Vagrant core when
      # a machine is created or its ID is updated.
      #
      # The guard clause ensures we only persist when the machine has a valid ID,
      # as some test scenarios may not have @machine.id available.
      #
      # @return [void]
      # @api public
      def machine_id_changed
        # Guard clause: Only persist if machine has an ID
        # Some test scenarios may not have @machine.id available
        return unless @machine.respond_to?(:id) && !@machine.id.nil?

        write_machine_id(@machine.id)
      end

      # Read the machine ID from persistent storage.
      #
      # Reads the machine ID from the id file in the data directory.
      # Returns nil if the file doesn't exist or cannot be read.
      #
      # @return [String, nil] The machine ID if found, nil otherwise
      # @raise [Errno::EACCES] If permission denied (logged and returns nil)
      # @raise [Errno::ENOENT] If file not found (logged and returns nil)
      # @raise [Encoding::InvalidByteSequenceError] If file contains invalid data (logged and returns nil)
      # @api public
      def read_machine_id
        return nil unless File.exist?(id_file_path)

        File.read(id_file_path).strip
      rescue Errno::EACCES, Errno::ENOENT, Encoding::InvalidByteSequenceError => e
        # Log error and return nil - graceful degradation for non-critical errors
        @machine.ui&.warn("OrbStack: Could not read machine ID: #{e.message}")
        nil
      end

      # Write the machine ID to persistent storage.
      #
      # Writes the machine ID to the id file in the data directory.
      # Creates the directory if it doesn't exist.
      #
      # @param [String] machine_id The machine ID to persist
      # @return [void]
      # @raise [Errno::EACCES] If permission denied
      # @raise [Errno::ENOSPC] If disk is full
      # @raise [Errno::EROFS] If filesystem is read-only
      # @api public
      def write_machine_id(machine_id)
        ensure_data_dir_exists
        File.write(id_file_path, machine_id)
      rescue Errno::EACCES, Errno::ENOSPC, Errno::EROFS => e
        # Log error and re-raise - critical errors that cannot be ignored
        @machine.ui&.error("OrbStack: Could not write machine ID: #{e.message}")
        raise
      end

      # Read machine metadata from persistent storage.
      #
      # Reads metadata from the metadata.json file in the data directory.
      # Returns an empty hash if the file doesn't exist or contains invalid JSON.
      #
      # @return [Hash] The metadata hash, or empty hash if not found
      # @raise [JSON::ParserError] If JSON is invalid (logged and returns {})
      # @raise [Errno::EACCES] If permission denied (logged and returns {})
      # @raise [Errno::ENOENT] If file not found (logged and returns {})
      # @raise [Encoding::InvalidByteSequenceError] If file contains invalid data (logged and returns {})
      # @api public
      def read_metadata
        return {} unless File.exist?(metadata_file_path)

        JSON.parse(File.read(metadata_file_path))
      rescue JSON::ParserError, Errno::EACCES, Errno::ENOENT, Encoding::InvalidByteSequenceError => e
        # Log error and return empty hash - graceful degradation for non-critical errors
        @machine.ui&.warn("OrbStack: Could not read metadata: #{e.message}")
        {}
      end

      # Write machine metadata to persistent storage.
      #
      # Writes metadata to the metadata.json file in the data directory.
      # Creates the directory if it doesn't exist. Formats JSON for readability.
      #
      # @param [Hash] metadata The metadata hash to persist
      # @return [void]
      # @raise [JSON::ParserError] If JSON generation fails
      # @raise [Errno::EACCES] If permission denied
      # @raise [Errno::ENOSPC] If disk is full
      # @raise [Errno::EROFS] If filesystem is read-only
      # @api public
      def write_metadata(metadata)
        ensure_data_dir_exists
        File.write(metadata_file_path, JSON.pretty_generate(metadata))
      rescue JSON::ParserError, Errno::EACCES, Errno::ENOSPC, Errno::EROFS => e
        # Log error and re-raise - critical errors that cannot be ignored
        @machine.ui&.error("OrbStack: Could not write metadata: #{e.message}")
        raise
      end

      private

      # Path to the machine ID file.
      #
      # @return [Pathname] Path to the ID file
      # @api private
      def id_file_path
        @machine.data_dir.join('id')
      end

      # Path to the metadata JSON file.
      #
      # @return [Pathname] Path to the metadata file
      # @api private
      def metadata_file_path
        @machine.data_dir.join('metadata.json')
      end

      # Ensure the data directory exists.
      #
      # Creates the data directory if it doesn't exist.
      #
      # @return [void]
      # @api private
      def ensure_data_dir_exists
        dir = @machine.data_dir
        FileUtils.mkdir_p(dir)
      end
    end
  end
end
