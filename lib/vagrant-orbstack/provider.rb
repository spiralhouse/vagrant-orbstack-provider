# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'vagrant-orbstack/errors'
require 'vagrant-orbstack/util/state_cache'
require 'vagrant-orbstack/util/orbstack_cli'
require 'vagrant-orbstack/action'

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
      # Creates and returns an Action::Builder containing the appropriate
      # middleware stack for the requested operation. Currently only :up
      # is implemented; other actions return nil.
      #
      # @param [Symbol] name The action name (:up, :halt, :destroy, etc.)
      # @return [Vagrant::Action::Builder, nil] Action middleware builder or nil
      # @api public
      # rubocop:disable Metrics/MethodLength
      def action(name)
        case name
        when :up
          Vagrant::Action::Builder.new.tap do |b|
            b.use Action::Create
          end
        when :halt
          Vagrant::Action::Builder.new.tap do |b|
            b.use Action::Halt
          end
        when :reload
          build_reload_action
        when :ssh_run
          Vagrant::Action::Builder.new.tap do |b|
            b.use Action::SSHRun
          end
        when :destroy
          Vagrant::Action::Builder.new.tap do |b|
            b.use Action::Destroy
          end
          # Return nil for unsupported actions (future stories, etc.)
        end
      end
      # rubocop:enable Metrics/MethodLength

      # Provide SSH connection information for the machine.
      #
      # Returns SSH connection parameters for Vagrant to connect to the machine
      # using OrbStack's SSH proxy architecture.
      #
      # CRITICAL: OrbStack uses SSH proxy at localhost:32222, NOT direct SSH to VM IP.
      #
      # Returns nil if the machine is not running.
      #
      # @return [Hash, nil] SSH connection parameters with keys:
      #   - :host - Always '127.0.0.1' (OrbStack SSH proxy, NOT VM IP)
      #   - :port - Always 32222 (OrbStack SSH proxy port, NOT 22)
      #   - :username - Machine ID for proxy routing
      #   - :private_key_path - OrbStack's auto-generated ED25519 key
      #   - :forward_agent - Whether to forward SSH agent (from config)
      # @api public
      def ssh_info
        # Return nil if machine is not running
        current_state = state
        return nil if %i[not_created stopped].include?(current_state.id)

        # Return OrbStack SSH proxy configuration
        {
          host: '127.0.0.1',
          port: 32_222,
          username: @machine.id,
          private_key_path: File.expand_path('~/.orbstack/ssh/id_ed25519'),
          proxy_command: orbstack_proxy_command,
          forward_agent: @machine.provider_config.forward_agent
        }
      end

      # Return current machine state.
      #
      # Queries OrbStack CLI to determine the current state of the machine.
      # Results are cached with a 5-second TTL to reduce redundant CLI calls.
      # State is automatically invalidated when state-changing actions occur.
      #
      # @return [Vagrant::MachineState] Current state of the machine
      # @api public
      def state
        # Return early if machine ID is nil
        return not_created_state('The machine has not been created') if @machine.id.nil?

        # Check cache first
        cached_state = state_cache.get(@machine.id)
        return cached_state if cached_state

        # Cache miss: Query OrbStack CLI
        query_and_cache_state
      rescue StandardError => e
        # Handle query errors gracefully
        handle_state_query_error(e)
      end

      # Invalidate the state cache.
      #
      # Clears all cached state entries, forcing the next state query to
      # fetch fresh data from OrbStack CLI. This is typically called by
      # action middleware after state-changing operations (create, start, stop).
      #
      # @return [void]
      # @api public
      def invalidate_state_cache
        state_cache.invalidate_all
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

      # Path to the machine ID file.
      #
      # @return [Pathname] Path to the ID file
      # @api public
      def id_file_path
        @machine.data_dir.join('id')
      end

      # Path to the metadata JSON file.
      #
      # @return [Pathname] Path to the metadata file
      # @api public
      def metadata_file_path
        @machine.data_dir.join('metadata.json')
      end

      private

      # Get the state cache instance.
      #
      # Lazy-initializes a StateCache instance with 5-second TTL.
      # The cache is shared across all state queries for this provider instance.
      #
      # @return [Util::StateCache] The state cache instance
      # @api private
      def state_cache
        @state_cache ||= Util::StateCache.new(ttl: 5)
      end

      # Generate OrbStack SSH ProxyCommand.
      #
      # OrbStack routes all SSH connections through the OrbStack Helper app
      # using a ProxyCommand. This returns the correctly formatted command
      # that Vagrant's SSH layer will use.
      #
      # @return [String] ProxyCommand string for SSH config
      # @api private
      def orbstack_proxy_command
        helper_path = '/Applications/OrbStack.app/Contents/Frameworks/' \
                      'OrbStack Helper.app/Contents/MacOS/OrbStack Helper'
        "'#{helper_path}' ssh-proxy-fdpass #{Process.uid}"
      end

      # Map OrbStack machine info to Vagrant state tuple.
      #
      # Converts OrbStack machine status to Vagrant state representation.
      # Returns a tuple of [state_id, short_description, long_description].
      #
      # @param machine_info [Hash, nil] Machine info from OrbStack CLI with :name and :status,
      #   or nil if machine was not found
      # @return [Array<Symbol, String, String>] Tuple of [state_id, short_desc, long_desc]
      # @api private
      def map_orbstack_state_to_vagrant(machine_info)
        if machine_info.nil?
          [:not_created, 'not created', 'Machine does not exist in OrbStack']
        elsif machine_info[:status] == 'running'
          [:running, 'running', 'Machine is running in OrbStack']
        elsif machine_info[:status] == 'stopped'
          [:stopped, 'stopped', 'Machine is stopped']
        else
          # Unknown state - treat as not created
          [:not_created, 'unknown', 'Machine state is unknown']
        end
      end

      # Create a :not_created MachineState with appropriate description.
      #
      # @param reason [String] The reason the machine is not created
      # @return [Vagrant::MachineState] A not_created state object
      # @api private
      def not_created_state(reason)
        Vagrant::MachineState.new(:not_created, 'not created', reason)
      end

      # Query OrbStack CLI for current machine state and cache result.
      #
      # @return [Vagrant::MachineState] The queried machine state
      # @api private
      def query_and_cache_state
        machines = Util::OrbStackCLI.list_machines
        our_machine = machines.find { |m| m[:name] == @machine.id }

        # Map OrbStack state to Vagrant state
        state_id, short_desc, long_desc = map_orbstack_state_to_vagrant(our_machine)

        # Create MachineState and cache it
        machine_state = Vagrant::MachineState.new(state_id, short_desc, long_desc)
        state_cache.set(@machine.id, machine_state)

        machine_state
      end

      # Handle error during state query and return not_created state.
      #
      # @param error [Exception] The error that occurred
      # @return [Vagrant::MachineState] A not_created state object
      # @api private
      def handle_state_query_error(error)
        if error.is_a?(CommandTimeoutError)
          @machine.ui.warn('OrbStack: Command timeout querying machine state')
          @logger.warn("State query timed out: #{error.message}")
          not_created_state('Timeout querying machine state')
        else
          @machine.ui.warn("OrbStack: Error querying machine state: #{error.message}")
          @logger.error("Failed to query machine state: #{error.message}")
          not_created_state('Error querying machine state')
        end
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

      # Build reload action: Halt → Start → (optional) Provision
      #
      # @param env [Hash] Environment hash (unused, for consistency)
      # @return [Vagrant::Action::Builder] Configured action builder
      # @api private
      def build_reload_action(_env = nil)
        Vagrant::Action::Builder.new.tap do |b|
          b.use Action::Halt
          b.use Action::Start
          include_provisioning(b)
        end
      end

      # Include provisioning middleware if available.
      #
      # Conditionally includes Vagrant's built-in Provision middleware.
      # Defensive check ensures compatibility if middleware isn't available.
      #
      # @param builder [Vagrant::Action::Builder] Builder to modify
      # @return [void]
      # @api private
      def include_provisioning(builder)
        return unless defined?(Vagrant::Action::Builtin::Provision)

        builder.use Vagrant::Action::Builtin::Provision
      end
    end
  end
end
