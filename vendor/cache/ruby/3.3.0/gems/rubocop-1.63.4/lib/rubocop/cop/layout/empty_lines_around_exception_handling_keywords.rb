# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks if empty lines exist around the bodies of `begin`
      # sections. This cop doesn't check empty lines at `begin` body
      # beginning/end and around method definition body.
      # `Style/EmptyLinesAroundBeginBody` or `Style/EmptyLinesAroundMethodBody`
      # can be used for this purpose.
      #
      # @example
      #
      #   # good
      #
      #   begin
      #     do_something
      #   rescue
      #     do_something2
      #   else
      #     do_something3
      #   ensure
      #     do_something4
      #   end
      #
      #   # good
      #
      #   def foo
      #     do_something
      #   rescue
      #     do_something2
      #   end
      #
      #   # bad
      #
      #   begin
      #     do_something
      #
      #   rescue
      #
      #     do_something2
      #
      #   else
      #
      #     do_something3
      #
      #   ensure
      #
      #     do_something4
      #   end
      #
      #   # bad
      #
      #   def foo
      #     do_something
      #
      #   rescue
      #
      #     do_something2
      #   end
      class EmptyLinesAroundExceptionHandlingKeywords < Base
        include EmptyLinesAroundBody
        extend AutoCorrector

        MSG = 'Extra empty line detected %<location>s the `%<keyword>s`.'

        def on_def(node)
          check_body(node.body, node.loc.line)
        end
        alias on_defs on_def
        alias on_block on_def
        alias on_numblock on_def

        def on_kwbegin(node)
          body, = *node
          check_body(body, node.loc.line)
        end

        private

        def check_body(body, line_of_def_or_kwbegin)
          locations = keyword_locations(body)

          locations.each do |loc|
            line = loc.line
            next if line == line_of_def_or_kwbegin || last_rescue_and_end_on_same_line(body)

            keyword = loc.source
            # below the keyword
            check_line(style, line, message('after', keyword), &:empty?)
            # above the keyword
            check_line(style, line - 2, message('before', keyword), &:empty?)
          end
        end

        def last_rescue_and_end_on_same_line(body)
          body.rescue_type? && body.resbody_branches.last.loc.line == body.parent.loc.end.line
        end

        def message(location, keyword)
          format(MSG, location: location, keyword: keyword)
        end

        def style
          :no_empty_lines
        end

        def keyword_locations(node)
          return [] unless node

          case node.type
          when :rescue
            keyword_locations_in_rescue(node)
          when :ensure
            keyword_locations_in_ensure(node)
          else
            []
          end
        end

        def keyword_locations_in_rescue(node)
          [node.loc.else, *node.resbody_branches.map { |body| body.loc.keyword }].compact
        end

        def keyword_locations_in_ensure(node)
          ensure_body, = *node
          [
            node.loc.keyword,
            *keyword_locations(ensure_body)
          ]
        end
      end
    end
  end
end
