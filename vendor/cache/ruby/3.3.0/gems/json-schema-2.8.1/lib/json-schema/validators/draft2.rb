require 'json-schema/schema/validator'

module JSON
  class Schema

    class Draft2 < Validator
      def initialize
        super
        @attributes = {
          "type" => JSON::Schema::TypeAttribute,
          "disallow" => JSON::Schema::DisallowAttribute,
          "format" => JSON::Schema::FormatAttribute,
          "maximum" => JSON::Schema::MaximumInclusiveAttribute,
          "minimum" => JSON::Schema::MinimumInclusiveAttribute,
          "minItems" => JSON::Schema::MinItemsAttribute,
          "maxItems" => JSON::Schema::MaxItemsAttribute,
          "uniqueItems" => JSON::Schema::UniqueItemsAttribute,
          "minLength" => JSON::Schema::MinLengthAttribute,
          "maxLength" => JSON::Schema::MaxLengthAttribute,
          "divisibleBy" => JSON::Schema::DivisibleByAttribute,
          "enum" => JSON::Schema::EnumAttribute,
          "properties" => JSON::Schema::PropertiesOptionalAttribute,
          "pattern" => JSON::Schema::PatternAttribute,
          "additionalProperties" => JSON::Schema::AdditionalPropertiesAttribute,
          "items" => JSON::Schema::ItemsAttribute,
          "extends" => JSON::Schema::ExtendsAttribute
        }
        @default_formats = {
          'date-time' => DateTimeFormat,
          'date' => DateFormat,
          'time' => TimeFormat,
          'ip-address' => IP4Format,
          'ipv6' => IP6Format,
          'uri' => UriFormat
        }
        @formats = @default_formats.clone
        @uri = JSON::Util::URI.parse("http://json-schema.org/draft-02/schema#")
        @names = ["draft2"]
        @metaschema_name = "draft-02.json"
      end

      JSON::Validator.register_validator(self.new)
    end

  end
end
