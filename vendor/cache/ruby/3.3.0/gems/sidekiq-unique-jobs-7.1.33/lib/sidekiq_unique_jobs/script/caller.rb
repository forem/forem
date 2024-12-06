# frozen_string_literal: true

module SidekiqUniqueJobs
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Script
    #
    # Module Caller provides the convenience method #call_script
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module Caller
      module_function

      # includes "SidekiqUniqueJobs::Connection"
      # @!parse include SidekiqUniqueJobs::Connection
      include SidekiqUniqueJobs::Connection

      #
      # Convenience method to reduce typing,
      #   calls redis lua scripts.
      #
      #
      # @overload call_script(file_name, keys, argv, conn)
      #   Call script without options hash
      #   @param [Symbol] file_name the name of the file
      #   @param [Array<String>] keys to pass to the the script
      #   @param [Array<String>] argv arguments to pass to the script
      #   @param [Redis] conn a redis connection
      # @overload call_script(file_name, conn, keys:, argv:)
      #   Call script with options hash
      #   @param [Symbol] file_name the name of the file
      #   @param [Redis] conn a redis connection
      #   @param [Hash] options arguments to pass to the script file
      #   @option options [Array] :keys to pass to the script
      #   @option options [Array] :argv arguments to pass to the script
      #
      # @return [true,false,String,Integer,Float,nil] returns the return value of the lua script
      #
      def call_script(file_name, *args)
        conn, keys, argv = extract_args(*args)
        return do_call(file_name, conn, keys, argv) if conn

        pool = defined?(redis_pool) ? redis_pool : nil

        redis(pool) do |new_conn|
          result = do_call(file_name, new_conn, keys, argv)
          yield result if block_given?
          result
        end
      end

      # Only used to reduce a little bit of duplication
      # @see call_script
      def do_call(file_name, conn, keys, argv)
        argv = argv.dup.push(
          now_f,
          debug_lua,
          max_history,
          file_name,
          redis_version,
        )
        Script.execute(file_name, conn, keys: keys, argv: argv)
      end

      #
      # Utility method to allow both symbol keys and arguments
      #
      # @overload call_script(file_name, keys, argv, conn)
      #   Call script without options hash
      #   @param [Symbol] file_name the name of the file
      #   @param [Array<String>] keys to pass to the the script
      #   @param [Array<String>] argv arguments to pass to the script
      #   @param [Redis] conn a redis connection
      # @overload call_script(file_name, conn, keys:, argv:)
      #   Call script with options hash
      #   @param [Symbol] file_name the name of the file
      #   @param [Redis] conn a redis connection
      #   @param [Hash] options arguments to pass to the script file
      #   @option options [Array] :keys to pass to the script
      #   @option options [Array] :argv arguments to pass to the script
      #
      # @return [Array<Redis, Array, Array>] <description>
      #
      def extract_args(*args)
        options = args.extract_options!
        if options.length.positive?
          [args.pop, options.fetch(:keys) { [] }, options.fetch(:argv) { [] }]
        else
          keys, argv = args.shift(2)
          keys ||= []
          argv ||= []
          [args.pop, keys, argv]
        end
      end

      #
      # @see SidekiqUniqueJobs#now_f
      #
      def now_f
        SidekiqUniqueJobs.now_f
      end

      #
      # @see SidekiqUniqueJobs::Config#debug_lua
      #
      def debug_lua
        SidekiqUniqueJobs.config.debug_lua
      end

      #
      # @see SidekiqUniqueJobs::Config#max_history
      #
      def max_history
        SidekiqUniqueJobs.config.max_history
      end

      #
      # @see SidekiqUniqueJobs::Config#max_history
      #
      def redis_version
        SidekiqUniqueJobs.config.redis_version
      end
    end
  end
end
