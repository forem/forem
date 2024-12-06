# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Emulates the following Ruby warning in Ruby 3.3.
      #
      # [source,ruby]
      # ----
      # $ ruby -e '0.times { it }'
      # -e:1: warning: `it` calls without arguments will refer to the first block param in Ruby 3.4;
      # use it() or self.it
      # ----
      #
      # `it` calls without arguments will refer to the first block param in Ruby 3.4.
      # So use `it()` or `self.it` to ensure compatibility.
      #
      # @example
      #
      #   # bad
      #   do_something { it }
      #
      #   # good
      #   do_something { it() }
      #   do_something { self.it }
      #
      class ItWithoutArgumentsInBlock < Base
        include NodePattern::Macros

        MSG = '`it` calls without arguments will refer to the first block param in Ruby 3.4; ' \
              'use `it()` or `self.it`.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless (body = node.body)
          return unless node.arguments.empty_and_without_delimiters?

          if body.send_type? && deprecated_it_method?(body)
            add_offense(body)
          else
            body.each_descendant(:send).each do |send_node|
              next unless deprecated_it_method?(send_node)

              add_offense(send_node)
            end
          end
        end

        def deprecated_it_method?(node)
          return false unless node.method?(:it)

          !node.receiver && node.arguments.empty? && !node.parenthesized? && !node.block_literal?
        end
      end
    end
  end
end
