# frozen_string_literal: true

require 'better_html'
require 'better_html/tree/tag'

module ERBLint
  module Linters
    # Allow `<script>` tags in ERB that have specific `type` attributes.
    # This only validates inline `<script>` tags, a separate rubocop cop
    # may be used to enforce the same rule when `javascript_tag` is called.
    class AllowedScriptType < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :allowed_types, accepts: array_of?(String),
          default: -> { ['text/javascript'] }
        property :allow_blank, accepts: [true, false], default: true, reader: :allow_blank?
        property :disallow_inline_scripts, accepts: [true, false], default: false, reader: :disallow_inline_scripts?
      end
      self.config_schema = ConfigSchema

      def run(processed_source)
        parser = processed_source.parser
        parser.nodes_with_type(:tag).each do |tag_node|
          tag = BetterHtml::Tree::Tag.from_node(tag_node)
          next if tag.closing?
          next unless tag.name == 'script'

          if @config.disallow_inline_scripts?
            name_node = tag_node.to_a[1]
            add_offense(
              name_node.loc,
              "Avoid using inline `<script>` tags altogether. "\
              "Instead, move javascript code into a static file."
            )
            next
          end

          type_attribute = tag.attributes['type']
          type_present = type_attribute.present? && type_attribute.value_node.present?

          if !type_present && !@config.allow_blank?
            name_node = tag_node.to_a[1]
            add_offense(
              name_node.loc,
              "Missing a `type=\"text/javascript\"` attribute to `<script>` tag.",
              [type_attribute]
            )
          elsif type_present && !@config.allowed_types.include?(type_attribute.value)
            add_offense(
              type_attribute.loc,
              "Avoid using #{type_attribute.value.inspect} as type for `<script>` tag. "\
              "Must be one of: #{@config.allowed_types.join(', ')}"\
              "#{' (or no type attribute)' if @config.allow_blank?}."
            )
          end
        end
      end

      def autocorrect(_processed_source, offense)
        return unless offense.context
        lambda do |corrector|
          type_attribute, = *offense.context
          if type_attribute.nil?
            corrector.insert_after(offense.source_range, ' type="text/javascript"')
          elsif !type_attribute.value.present?
            corrector.replace(type_attribute.node.loc, 'type="text/javascript"')
          end
        end
      end
    end
  end
end
