# frozen_string_literal: true

module Brpoplpush
  module RedisScript
    # Interface to dealing with .lua files
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Scripts
      #
      # @return [Concurrent::Map] a map with configured script paths
      SCRIPT_PATHS = Concurrent::Map.new

      #
      # Fetch a scripts configuration for path
      #
      # @param [Pathname] root_path the path to scripts
      #
      # @return [Scripts] a collection of scripts
      #
      def self.fetch(root_path)
        if (scripts = SCRIPT_PATHS.get(root_path))
          return scripts
        end

        create(root_path)
      end

      #
      # Create a new scripts collection based on path
      #
      # @param [Pathname] root_path the path to scripts
      #
      # @return [Scripts] a collection of scripts
      #
      def self.create(root_path)
        scripts = new(root_path)
        store(scripts)
      end

      #
      # Store the scripts collection in memory
      #
      # @param [Scripts] scripts the path to scripts
      #
      # @return [Scripts] the scripts instance that was stored
      #
      def self.store(scripts)
        SCRIPT_PATHS.put(scripts.root_path, scripts)
        scripts
      end

      #
      # @!attribute [r] scripts
      #   @return [Concurrent::Map] a collection of loaded scripts
      attr_reader :scripts

      #
      # @!attribute [r] root_path
      #   @return [Pathname] the path to the directory with lua scripts
      attr_reader :root_path

      def initialize(path)
        raise ArgumentError, "path needs to be a Pathname" unless path.is_a?(Pathname)

        @scripts   = Concurrent::Map.new
        @root_path = path
      end

      def fetch(name, conn)
        if (script = scripts.get(name.to_sym))
          return script
        end

        load(name, conn)
      end

      def load(name, conn)
        script = Script.load(name, root_path, conn)
        scripts.put(name.to_sym, script)

        script
      end

      def delete(script)
        if script.is_a?(Script)
          scripts.delete(script.name)
        else
          scripts.delete(script.to_sym)
        end
      end

      def kill(conn)
        if conn.respond_to?(:namespace)
          conn.redis.script(:kill)
        else
          conn.script(:kill)
        end
      end

      #
      # Execute a lua script with given name
      #
      # @note this method is recursive if we need to load a lua script
      #   that wasn't previously loaded.
      #
      # @param [Symbol] name the name of the script to execute
      # @param [Redis] conn the redis connection to use for execution
      # @param [Array<String>] keys script keys
      # @param [Array<Object>] argv script arguments
      #
      # @return value from script
      #
      def execute(name, conn, keys: [], argv: [])
        script = fetch(name, conn)
        conn.evalsha(script.sha, keys, argv)
      end

      def count
        scripts.keys.size
      end
    end
  end
end
