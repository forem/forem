# frozen_string_literal: true

module Brpoplpush
  module RedisScript
    # Interface to dealing with .lua files
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Client
      include Brpoplpush::RedisScript::Timing

      #
      # @!attribute [r] logger
      #   @return [Logger] an instance of a logger
      attr_reader :logger
      #
      # @!attribute [r] file_name
      #   @return [String] The name of the file to execute
      attr_reader :config
      #
      # @!attribute [r] scripts
      #   @return [Scripts] the collection with loaded scripts
      attr_reader :scripts

      def initialize(config)
        @config  = config
        @logger  = config.logger
        @scripts = Scripts.fetch(config.scripts_path)
      end

      #
      # Execute a lua script with the provided script_name
      #
      # @note this method is recursive if we need to load a lua script
      #   that wasn't previously loaded.
      #
      # @param [Symbol] script_name the name of the script to execute
      # @param [Redis] conn the redis connection to use for execution
      # @param [Array<String>] keys script keys
      # @param [Array<Object>] argv script arguments
      #
      # @return value from script
      #
      def execute(script_name, conn, keys: [], argv: [])
        result, elapsed = timed do
          scripts.execute(script_name, conn, keys: keys, argv: argv)
        end

        logger.debug("Executed #{script_name}.lua in #{elapsed}ms")
        result
      rescue ::Redis::CommandError => ex
        handle_error(script_name, conn, ex) do
          execute(script_name, conn, keys: keys, argv: argv)
        end
      end

      private

      #
      # Handle errors to allow retrying errors that need retrying
      #
      # @param [Redis::CommandError] ex exception to handle
      #
      # @return [void]
      #
      # @yieldreturn [void] yields back to the caller when NOSCRIPT is raised
      def handle_error(script_name, conn, ex)
        case ex.message
        when /NOSCRIPT/
          handle_noscript(script_name) { return yield }
        when /BUSY/
          handle_busy(conn) { return yield }
        end

        raise unless LuaError.intercepts?(ex)

        script = scripts.fetch(script_name, conn)
        raise LuaError.new(ex, script)
      end

      def handle_noscript(script_name)
        scripts.delete(script_name)
        yield
      end

      def handle_busy(conn)
        scripts.kill(conn)
      rescue ::Redis::CommandError => ex
        logger.warn(ex)
      ensure
        yield
      end
    end
  end
end
