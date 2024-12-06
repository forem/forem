# frozen_string_literal: true

require "smart_properties"

module BetterHtml
  class Config
    include SmartProperties

    property :partial_tag_name_pattern, default: -> { /\A[a-z0-9\-\:]+\z/ }
    property :partial_attribute_name_pattern, default: -> { /\A[a-zA-Z0-9\-\:]+\z/ }
    property :allow_single_quoted_attributes, default: true
    property :allow_unquoted_attributes, default: false
    property :javascript_safe_methods, default: -> { ["to_json"] }
    property :javascript_attribute_names, default: -> { [/\Aon/i] }
    property :template_exclusion_filter
    property :lodash_safe_javascript_expression, default: -> { [/\AJSON\.stringify\(/] }
    property :disable_parser_validation, default: false

    def javascript_attribute_name?(name)
      javascript_attribute_names.any? { |other| other === name.to_s } # rubocop:disable Style/CaseEquality
    end

    def lodash_safe_javascript_expression?(code)
      lodash_safe_javascript_expression.any? { |other| other === code } # rubocop:disable Style/CaseEquality
    end

    def javascript_safe_method?(name)
      javascript_safe_methods.include?(name.to_s)
    end
  end
end
