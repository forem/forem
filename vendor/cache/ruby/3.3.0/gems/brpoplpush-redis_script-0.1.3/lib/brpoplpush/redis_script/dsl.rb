# frozen_string_literal: true

require "pathname"
require "digest/sha1"
require "concurrent/map"

module Brpoplpush
  module RedisScript
    # Interface to dealing with .lua files
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    module DSL
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      #
      # Module ClassMethods extends the base class with necessary methods
      #
      # @author Mikael Henriksson <mikael@zoolutions.se>
      #
      module ClassMethods
        def execute(file_name, conn, keys: [], argv: [])
          Brpoplpush::RedisScript::Client
            .new(config)
            .execute(file_name, conn, keys: keys, argv: argv)
        end

        # Configure the gem
        #
        # This is usually called once at startup of an application
        # @param [Hash] options global gem options
        # @option options [String, Pathname] :path
        # @option options [Logger] :logger (default is Logger.new(STDOUT))
        # @yield control to the caller when given block
        def configure(options = {})
          if block_given?
            yield config
          else
            options.each do |key, val|
              config.send("#{key}=", val)
            end
          end
        end

        #
        # The current configuration (See: {.configure} on how to configure)
        #
        #
        # @return [RedisScript::Config] the gem configuration
        #
        def config
          @config ||= Config.new
        end
      end
    end
  end
end
