# frozen_string_literal: true

module BetterHtml
  class HtmlAttributes
    def initialize(data)
      @data = data.stringify_keys
    end

    def to_s
      @data.map do |key, value|
        unless key =~ BetterHtml.config.partial_attribute_name_pattern
          raise ArgumentError,
            "Attribute names must match the pattern #{BetterHtml.config.partial_attribute_name_pattern.inspect}"
        end

        if value.nil?
          key.to_s
        else
          value = value.to_s
          escaped_value = value.html_safe? ? value : CGI.escapeHTML(value)
          if escaped_value.include?('"')
            raise ArgumentError, "The value provided for attribute '#{key}' contains a `\"` "\
              "character which is not allowed. Did you call .html_safe without properly escaping this data?"
          end
          "#{key}=\"#{escaped_value}\""
        end
      end.join(" ")
    end
  end
end
