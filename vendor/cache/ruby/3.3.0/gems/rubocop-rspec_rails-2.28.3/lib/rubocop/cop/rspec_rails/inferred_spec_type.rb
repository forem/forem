# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Identifies redundant spec type.
      #
      # After setting up rspec-rails, you will have enabled
      # `config.infer_spec_type_from_file_location!` by default in
      # spec/rails_helper.rb. This cop works in conjunction with this config.
      # If you disable this config, disable this cop as well.
      #
      # @safety
      #   This cop is marked as unsafe because
      #   `config.infer_spec_type_from_file_location!` may not be enabled.
      #
      # @example
      #   # bad
      #   # spec/models/user_spec.rb
      #   RSpec.describe User, type: :model do
      #   end
      #
      #   # good
      #   # spec/models/user_spec.rb
      #   RSpec.describe User do
      #   end
      #
      #   # good
      #   # spec/models/user_spec.rb
      #   RSpec.describe User, type: :common do
      #   end
      #
      # @example `Inferences` configuration
      #   # .rubocop.yml
      #   # RSpecRails/InferredSpecType:
      #   #   Inferences:
      #   #     services: service
      #
      #   # bad
      #   # spec/services/user_spec.rb
      #   RSpec.describe User, type: :service do
      #   end
      #
      #   # good
      #   # spec/services/user_spec.rb
      #   RSpec.describe User do
      #   end
      #
      #   # good
      #   # spec/services/user_spec.rb
      #   RSpec.describe User, type: :common do
      #   end
      class InferredSpecType < ::RuboCop::Cop::RSpec::Base
        extend AutoCorrector

        MSG = 'Remove redundant spec type.'

        # @param [RuboCop::AST::BlockNode] node
        def on_block(node)
          return unless example_group?(node)

          pair_node = describe_with_type(node)
          return unless pair_node
          return unless inferred_type?(pair_node)

          removable_node = detect_removable_node(pair_node)
          add_offense(removable_node) do |corrector|
            autocorrect(corrector, removable_node)
          end
        end
        alias on_numblock on_block

        private

        # @!method describe_with_type(node)
        #   @param [RuboCop::AST::BlockNode] node
        #   @return [RuboCop::AST::PairNode, nil]
        def_node_matcher :describe_with_type, <<~PATTERN
          (block
            (send #rspec? #ExampleGroups.all
              ...
              (hash <$(pair (sym :type) sym) ...>)
            )
            ...
          )
        PATTERN

        # @param [RuboCop::AST::Corrector] corrector
        # @param [RuboCop::AST::Node] node
        def autocorrect(corrector, node)
          corrector.remove(remove_range(node))
        end

        # @param [RuboCop::AST::Node] node
        # @return [Parser::Source::Range]
        def remove_range(node)
          if node.left_sibling
            node.source_range.with(
              begin_pos: node.left_sibling.source_range.end_pos
            )
          elsif node.right_sibling
            node.source_range.with(
              end_pos: node.right_sibling.source_range.begin_pos
            )
          end
        end

        # @param [RuboCop::AST::PairNode] node
        # @return [RuboCop::AST::Node]
        def detect_removable_node(node)
          if node.parent.pairs.size == 1
            node.parent
          else
            node
          end
        end

        # @return [String]
        def file_path
          processed_source.file_path
        end

        # @param [RuboCop::AST::PairNode] node
        # @return [Boolean]
        def inferred_type?(node)
          inferred_type_from_file_path.inspect == node.value.source
        end

        # @return [Symbol, nil]
        def inferred_type_from_file_path
          inferences.find do |prefix, type|
            break type.to_sym if file_path.include?("spec/#{prefix}/")
          end
        end

        # @return [Hash]
        def inferences
          cop_config['Inferences'] || {}
        end
      end
    end
  end
end
