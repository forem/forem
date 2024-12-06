# frozen_string_literal: true

require "action_view"
require_relative "runtime_checks"

module BetterHtml
  class BetterErb
    class ErubiImplementation < ActionView::Template::Handlers::ERB::Erubi
      include RuntimeChecks

      def add_text(text)
        return if text.empty?

        if text == "\n"
          @parser.parse("\n")
          @newline_pending += 1
        else
          src << "@output_buffer.safe_append='"
          src << "\n" * @newline_pending if @newline_pending > 0
          src << escape_text(text)
          src << "'.freeze;"

          @parser.parse(text) do |*args|
            check_token(*args)
          end

          @newline_pending = 0
        end
      end

      def add_expression(indicator, code)
        if (indicator == "==") || @escape
          add_expr_auto_escaped(src, code, false)
        else
          add_expr_auto_escaped(src, code, true)
        end
      end

      def add_code(code)
        flush_newline_if_pending(src)

        block_check(src, "<%#{code}%>")
        @parser.append_placeholder(code)
        super
      end

      private

      def escape_text(text)
        text.gsub(/['\\]/, '\\\\\&')
      end
    end
  end
end
