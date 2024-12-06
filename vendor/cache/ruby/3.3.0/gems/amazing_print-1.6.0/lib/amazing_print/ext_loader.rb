# frozen_string_literal: true

module AmazingPrint
  ##
  # Attempt to load extensions up to 3 times since this library may be required
  # before dependencies that we have extensions for.
  #
  class ExtLoader
    EXT_LOAD_ATTEMPT_LIMIT = 3

    @load_attemps = 0

    def self.call
      return if @load_attemps >= EXT_LOAD_ATTEMPT_LIMIT

      require_relative 'ext/mongo_mapper'   if defined?(MongoMapper)
      require_relative 'ext/mongoid'        if defined?(Mongoid)
      require_relative 'ext/nobrainer'      if defined?(NoBrainer)
      require_relative 'ext/nokogiri'       if defined?(Nokogiri)
      require_relative 'ext/ostruct'        if defined?(OpenStruct) # rubocop:disable Style/OpenStructUse
      require_relative 'ext/ripple'         if defined?(Ripple)
      require_relative 'ext/sequel'         if defined?(Sequel)

      @load_attemps += 1
    end
  end
end
