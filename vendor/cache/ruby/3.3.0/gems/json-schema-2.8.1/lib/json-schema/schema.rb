require 'pathname'

module JSON
  class Schema

    attr_accessor :schema, :uri, :validator

    def initialize(schema,uri,parent_validator=nil)
      @schema = schema
      @uri = uri

      # If there is an ID on this schema, use it to generate the URI
      if @schema['id'] && @schema['id'].kind_of?(String)
        temp_uri = JSON::Util::URI.parse(@schema['id'])
        if temp_uri.relative?
          temp_uri = uri.join(temp_uri)
        end
        @uri = temp_uri
      end
      @uri = JSON::Util::URI.strip_fragment(@uri)

      # If there is a $schema on this schema, use it to determine which validator to use
      if @schema['$schema']
        @validator = JSON::Validator.validator_for_uri(@schema['$schema'])
      elsif parent_validator
        @validator = parent_validator
      else
        @validator = JSON::Validator.default_validator
      end
    end

    def validate(data, fragments, processor, options = {})
      @validator.validate(self, data, fragments, processor, options)
    end

    def self.stringify(schema)
      case schema
      when Hash then
        Hash[schema.map { |key, value| [key.to_s, stringify(schema[key])] }]
      when Array then
        schema.map do |schema_item|
          stringify(schema_item)
        end
      when Symbol then
        schema.to_s
      else
        schema
      end
    end

    # @return [JSON::Schema] a new schema matching an array whose items all match this schema.
    def to_array_schema
      array_schema = { 'type' => 'array', 'items' => schema }
      array_schema['$schema'] = schema['$schema'] unless schema['$schema'].nil?
      self.class.new(array_schema, uri, validator)
    end

    def to_s
      @schema.to_json
    end
  end
end
