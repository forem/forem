# frozen_string_literal: true

require "concurrent/map"
require "concurrent/mutable_struct"
require "digest/sha1"
require "logger"
require "pathname"
require "redis"

require "brpoplpush/redis_script/version"
require "brpoplpush/redis_script/template"
require "brpoplpush/redis_script/lua_error"
require "brpoplpush/redis_script/script"
require "brpoplpush/redis_script/scripts"
require "brpoplpush/redis_script/config"
require "brpoplpush/redis_script/timing"
require "brpoplpush/redis_script/logging"
require "brpoplpush/redis_script/dsl"
require "brpoplpush/redis_script/client"

module Brpoplpush
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module RedisScript
    module_function

    include Brpoplpush::RedisScript::DSL

    #
    # The current gem version
    #
    #
    # @return [String] the current gem version
    #
    def version
      VERSION
    end

    #
    # The current logger
    #
    #
    # @return [Logger] the configured logger
    #
    def logger
      config.logger
    end

    #
    # Set a new logger
    #
    # @param [Logger] other another logger
    #
    # @return [Logger] the new logger
    #
    def logger=(other)
      config.logger = other
    end

    #
    # Execute the given script_name
    #
    #
    # @param [Symbol] script_name the name of the lua script
    # @param [Array<String>] keys script keys
    # @param [Array<Object>] argv script arguments
    # @param [Redis] conn the redis connection to use
    #
    # @return value from script
    #
    def execute(script_name, conn, keys: [], argv: [])
      Client.execute(script_name, conn, keys: keys, argv: argv)
    end
  end
end
