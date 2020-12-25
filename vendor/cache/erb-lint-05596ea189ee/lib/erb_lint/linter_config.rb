# frozen_string_literal: true

require 'active_support'
require 'smart_properties'

module ERBLint
  class LinterConfig
    include SmartProperties

    class Error < StandardError; end

    class << self
      def array_of?(klass)
        lambda { |value| value.is_a?(Array) && value.all? { |s| s.is_a?(klass) } }
      end

      def to_array_of(klass)
        lambda { |entries| entries.map { |entry| klass.new(entry) } }
      end
    end

    property :enabled, accepts: [true, false], default: false, reader: :enabled?
    property :exclude, accepts: array_of?(String), default: -> { [] }

    def initialize(config = {})
      config = config.dup.deep_stringify_keys
      allowed_keys = self.class.properties.keys.map(&:to_s)
      given_keys = config.keys
      if (extra_keys = given_keys - allowed_keys).any?
        raise Error, "Given key is not allowed: #{extra_keys.join(', ')}"
      end
      super(config)
    rescue SmartProperties::InitializationError => e
      raise Error, "The following properties are required to be set: #{e.properties}"
    rescue SmartProperties::InvalidValueError => e
      raise Error, e.message
    end

    def [](name)
      unless self.class.properties.key?(name)
        raise Error, "No such property: #{name}"
      end
      super
    end

    def to_hash
      {}.tap do |hash|
        self.class.properties.to_hash.each_key do |key|
          hash[key.to_s] = self[key]
        end
      end
    end

    def excludes_file?(filename)
      exclude.any? do |path|
        File.fnmatch?(path, filename)
      end
    end
  end
end
