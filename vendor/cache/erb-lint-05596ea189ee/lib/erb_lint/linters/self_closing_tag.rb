# frozen_string_literal: true

module ERBLint
  module Linters
    # Warns when a tag is not self-closed properly.
    class SelfClosingTag < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :enforced_style, converts: :to_sym, accepts: [:always, :never], default: :never
      end
      self.config_schema = ConfigSchema

      SELF_CLOSING_TAGS = %w(
        area base br col command embed hr input keygen
        link menuitem meta param source track wbr img
      )

      def run(processed_source)
        processed_source.ast.descendants(:tag).each do |tag_node|
          tag = BetterHtml::Tree::Tag.from_node(tag_node)
          next unless SELF_CLOSING_TAGS.include?(tag.name)

          if tag.closing?
            start_solidus = tag_node.children.first
            add_offense(
              start_solidus.loc,
              "Tag `#{tag.name}` is a void element, it must not start with `</`.",
              ''
            )
          end

          if @config.enforced_style == :always && !tag.self_closing?
            add_offense(
              tag_node.loc.end.offset(-1),
              "Tag `#{tag.name}` is self-closing, it must end with `/>`.",
              '/'
            )
          end

          next unless @config.enforced_style == :never && tag.self_closing?
          end_solidus = tag_node.children.last
          add_offense(
            end_solidus.loc,
            "Tag `#{tag.name}` is a void element, it must end with `>` and not `/>`.",
            ''
          )
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, offense.context)
        end
      end
    end
  end
end
