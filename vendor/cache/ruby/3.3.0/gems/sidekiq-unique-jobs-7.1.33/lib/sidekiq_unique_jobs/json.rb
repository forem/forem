# frozen_string_literal: true

module SidekiqUniqueJobs
  # Handles loading and dumping of json
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module JSON
    module_function

    #
    # Parses a JSON string into an object
    #
    # @param [String] string the object to parse
    #
    # @return [Object]
    #
    def load_json(string)
      return if string.nil? || string.empty?

      ::JSON.parse(string)
    end

    #
    # Prevents trying JSON.load from raising errors given argument is a hash
    #
    # @param [String, Hash] string the JSON string to parse
    #
    # @return [Hash,Array]
    #
    def safe_load_json(string)
      return string if string.is_a?(Hash)

      load_json(string)
    end

    #
    # Dumps an object into a JSON string
    #
    # @param [Object] object a JSON convertible object
    #
    # @return [String] a JSON string
    #
    def dump_json(object)
      ::JSON.generate(object)
    end
  end
end
