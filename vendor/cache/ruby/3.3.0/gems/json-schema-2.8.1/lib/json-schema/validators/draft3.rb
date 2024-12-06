require 'json-schema/schema/validator'

module JSON
  class Schema

    class Draft3 < Validator
      def initialize
        super
        @attributes = {
          "type" => JSON::Schema::TypeAttribute,
          "disallow" => JSON::Schema::DisallowAttribute,
          "format" => JSON::Schema::FormatAttribute,
          "maximum" => JSON::Schema::MaximumAttribute,
          "minimum" => JSON::Schema::MinimumAttribute,
          "minItems" => JSON::Schema::MinItemsAttribute,
          "maxItems" => JSON::Schema::MaxItemsAttribute,
          "uniqueItems" => JSON::Schema::UniqueItemsAttribute,
          "minLength" => JSON::Schema::MinLengthAttribute,
          "maxLength" => JSON::Schema::MaxLengthAttribute,
          "divisibleBy" => JSON::Schema::DivisibleByAttribute,
          "enum" => JSON::Schema::EnumAttribute,
          "properties" => JSON::Schema::PropertiesAttribute,
          "pattern" => JSON::Schema::PatternAttribute,
          "patternProperties" => JSON::Schema::PatternPropertiesAttribute,
          "additionalProperties" => JSON::Schema::AdditionalPropertiesAttribute,
          "items" => JSON::Schema::ItemsAttribute,
          "additionalItems" => JSON::Schema::AdditionalItemsAttribute,
          "dependencies" => JSON::Schema::DependenciesAttribute,
          "extends" => JSON::Schema::ExtendsAttribute,
          "$ref" => JSON::Schema::RefAttribute
        }
        @default_formats = {
          'date-time' => DateTimeFormat,
          'date' => DateFormat,
          'ip-address' => IP4Format,
          'ipv6' => IP6Format,
          'time' => TimeFormat,
          'uri' => UriFormat
        }
        @formats = @default_formats.clone
        @uri = JSON::Util::URI.parse("http://json-schema.org/draft-03/schema#")
        @names = ["draft3", "http://json-schema.org/draft-03/schema#"]
        @metaschema_name = "draft-03.json"
      end

      JSON::Validator.register_validator(self.new)
    end

  end
end
