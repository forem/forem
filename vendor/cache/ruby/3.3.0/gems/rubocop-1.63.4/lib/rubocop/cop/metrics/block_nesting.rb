# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks for excessive nesting of conditional and looping
      # constructs.
      #
      # You can configure if blocks are considered using the `CountBlocks`
      # option. When set to `false` (the default) blocks are not counted
      # towards the nesting level. Set to `true` to count blocks as well.
      #
      # The maximum level of nesting allowed is configurable.
      class BlockNesting < Base
        NESTING_BLOCKS = %i[case case_match if while while_post until until_post for resbody].freeze

        exclude_limit 'Max'

        def on_new_investigation
          return if processed_source.blank?

          max = cop_config['Max']
          check_nesting_level(processed_source.ast, max, 0)
        end

        private

        def check_nesting_level(node, max, current_level)
          if consider_node?(node)
            current_level += 1 unless node.if_type? && node.elsif?
            if current_level > max
              self.max = current_level
              unless part_of_ignored_node?(node)
                add_offense(node, message: message(max)) { ignore_node(node) }
              end
            end
          end

          node.each_child_node do |child_node|
            check_nesting_level(child_node, max, current_level)
          end
        end

        def consider_node?(node)
          return true if NESTING_BLOCKS.include?(node.type)

          count_blocks? && (node.block_type? || node.numblock_type?)
        end

        def message(max)
          "Avoid more than #{max} levels of block nesting."
        end

        def count_blocks?
          cop_config['CountBlocks']
        end
      end
    end
  end
end
