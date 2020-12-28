# frozen_string_literal: true

module ERBLint
  module Linters
    # In ERB, right trim can be either =%> or -%>
    # this linter will force one or the other.
    class RightTrim < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :enforced_style, accepts: ['-', '='], default: '-'
      end
      self.config_schema = ConfigSchema

      def run(processed_source)
        processed_source.ast.descendants(:erb).each do |erb_node|
          _, _, _, trim_node = *erb_node
          next if trim_node.nil? || trim_node.loc.source == @config.enforced_style

          add_offense(
            trim_node.loc,
            "Prefer #{@config.enforced_style}%> instead of #{trim_node.loc.source}%> for trimming on the right."
          )
        end
      end

      def autocorrect(_processed_source, offense)
        lambda do |corrector|
          corrector.replace(offense.source_range, @config.enforced_style)
        end
      end
    end
  end
end
