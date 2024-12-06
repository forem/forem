# frozen_string_literal: true

module Brpoplpush
  module RedisScript
    #
    # Class holding gem configuration
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Config
      #
      # @!attribute [r] logger
      #   @return [Logger] a logger to use for debugging
      attr_reader :logger
      #
      # @!attribute [r] scripts_path
      #   @return [Pathname] a directory with lua scripts
      attr_reader :scripts_path

      #
      # Initialize a new instance of {Config}
      #
      #
      def initialize
        @conn         = Redis.new
        @logger       = Logger.new($stdout)
        @scripts_path = nil
      end

      #
      # Sets a value for scripts_path
      #
      # @param [String, Pathname] obj <description>
      #
      # @raise [ArgumentError] when directory does not exist
      # @raise [ArgumentError] when argument isn't supported
      #
      # @return [Pathname]
      #
      def scripts_path=(obj)
        raise ArgumentError, "#{obj} should be a Pathname or String" unless obj.is_a?(Pathname) || obj.is_a?(String)
        raise ArgumentError, "#{obj} does not exist" unless Dir.exist?(obj.to_s)

        @scripts_path =
          case obj
          when String
            Pathname.new(obj)
          else
            obj
          end
      end

      #
      # Sets a value for logger
      #
      # @param [Logger] obj a logger to use
      #
      # @raise [ArgumentError] when given argument isn't a Logger
      #
      # @return [Logger]
      #
      def logger=(obj)
        raise ArgumentError, "#{obj} should be a Logger" unless obj.is_a?(Logger)

        @logger = obj
      end
    end
  end
end
