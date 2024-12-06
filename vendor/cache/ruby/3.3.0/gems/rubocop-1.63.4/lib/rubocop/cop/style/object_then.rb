# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of consistent method names
      # `Object#yield_self` or `Object#then`.
      #
      # @example EnforcedStyle: then (default)
      #
      #   # bad
      #   obj.yield_self { |x| x.do_something }
      #
      #   # good
      #   obj.then { |x| x.do_something }
      #
      # @example EnforcedStyle: yield_self
      #
      #   # bad
      #   obj.then { |x| x.do_something }
      #
      #   # good
      #   obj.yield_self { |x| x.do_something }
      #
      class ObjectThen < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.6

        MSG = 'Prefer `%<prefer>s` over `%<current>s`.'

        def on_block(node)
          check_method_node(node.send_node)
        end

        alias on_numblock on_block

        def on_send(node)
          return unless node.arguments.one? && node.first_argument.block_pass_type?

          check_method_node(node)
        end

        private

        def check_method_node(node)
          return unless preferred_method?(node)

          message = message(node)
          add_offense(node.loc.selector, message: message) do |corrector|
            prefer = style == :then && node.receiver.nil? ? 'self.then' : style

            corrector.replace(node.loc.selector, prefer)
          end
        end

        def preferred_method?(node)
          case style
          when :then
            node.method?(:yield_self)
          when :yield_self
            node.method?(:then)
          else
            false
          end
        end

        def message(node)
          format(MSG, prefer: style.to_s, current: node.method_name)
        end
      end
    end
  end
end
