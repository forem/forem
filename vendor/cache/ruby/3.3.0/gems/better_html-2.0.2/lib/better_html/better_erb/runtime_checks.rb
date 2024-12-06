# frozen_string_literal: true

require "action_view"

module BetterHtml
  class BetterErb
    module RuntimeChecks
      def initialize(erb, config: BetterHtml.config, **options)
        @parser = HtmlTokenizer::Parser.new
        @config = config
        super(erb, **options)
      end

      def validate!
        check_parser_errors unless @config.disable_parser_validation

        unless @parser.context == :none
          raise BetterHtml::HtmlError, "Detected an open tag at the end of this document."
        end
      end

      private

      def class_name
        "BetterHtml::BetterErb::ValidatedOutputBuffer"
      end

      def wrap_method
        "#{class_name}.wrap"
      end

      def add_expr_auto_escaped(src, code, auto_escape)
        flush_newline_if_pending(src)

        escaped_code = escape_text(code)

        src << "#{wrap_method}(@output_buffer, (#{parser_context.inspect}), '#{escaped_code}'.freeze, #{auto_escape})"
        method_name = "safe_#{@parser.context}_append"
        if code =~ self.class::BLOCK_EXPR
          block_check(src, "<%=#{code}%>")
          src << ".#{method_name}= " << code
        else
          src << ".#{method_name}=(" << code << ");"
        end
        @parser.append_placeholder("<%=#{code}%>")
      end

      def parser_context
        if [:quoted_value, :unquoted_value, :space_after_attribute].include?(@parser.context)
          {
            tag_name: @parser.tag_name,
            attribute_name: @parser.attribute_name,
            attribute_value: @parser.attribute_value,
            attribute_quoted: @parser.attribute_quoted?,
            quote_character: @parser.quote_character,
          }
        elsif [:attribute_name, :after_attribute_name, :after_equal].include?(@parser.context)
          {
            tag_name: @parser.tag_name,
            attribute_name: @parser.attribute_name,
          }
        elsif [:tag, :tag_name, :tag_end].include?(@parser.context)
          {
            tag_name: @parser.tag_name,
          }
        elsif @parser.context == :rawtext
          {
            tag_name: @parser.tag_name,
            rawtext_text: @parser.rawtext_text,
          }
        elsif @parser.context == :comment
          {
            comment_text: @parser.comment_text,
          }
        elsif [:none, :solidus_or_tag_name].include?(@parser.context)
          {}
        else
          raise "Tried to interpolate into unknown location #{@parser.context}."
        end
      end

      def block_check(src, code)
        unless @parser.context == :none || @parser.context == :rawtext
          s = +"Ruby statement not allowed.\n"
          s << "In '#{@parser.context}' on line #{@parser.line_number} column #{@parser.column_number}:\n"
          prefix = extract_line(@parser.line_number)
          code = code.lines.first
          s << "#{prefix}#{code}\n"
          s << "#{" " * prefix.size}#{"^" * code.size}"
          raise BetterHtml::DontInterpolateHere, s
        end
      end

      def check_parser_errors
        errors = @parser.errors
        return if errors.empty?

        s = +"#{errors.size} error(s) found in HTML document.\n"
        errors.each do |error|
          s << "#{error.message}\n"
          s << "On line #{error.line} column #{error.column}:\n"
          line = extract_line(error.line)
          s << "#{line}\n"
          s << "#{" " * error.column}#{"^" * (line.size - error.column)}"
        end

        raise BetterHtml::HtmlError, s
      end

      def check_token(type, *args)
        check_tag_name(type, *args) if type == :tag_name
        check_attribute_name(type, *args) if type == :attribute_name
        check_quoted_value(type, *args) if type == :attribute_quoted_value_start
        check_unquoted_value(type, *args) if type == :attribute_unquoted_value
      end

      def check_tag_name(type, start, stop, line, column)
        text = @parser.document[start...stop]
        return if text.upcase == "!DOCTYPE"
        return if @config.partial_tag_name_pattern.match?(text)

        s = +"Invalid tag name #{text.inspect} does not match "\
          "regular expression #{@config.partial_tag_name_pattern.inspect}\n"
        s << build_location(line, column, text.size)
        raise BetterHtml::HtmlError, s
      end

      def check_attribute_name(type, start, stop, line, column)
        text = @parser.document[start...stop]
        return if @config.partial_attribute_name_pattern.match?(text)

        s = +"Invalid attribute name #{text.inspect} does not match "\
          "regular expression #{@config.partial_attribute_name_pattern.inspect}\n"
        s << build_location(line, column, text.size)
        raise BetterHtml::HtmlError, s
      end

      def check_quoted_value(type, start, stop, line, column)
        return if @config.allow_single_quoted_attributes

        text = @parser.document[start...stop]
        return if text == '"'

        s = +"Single-quoted attributes are not allowed\n"
        s << build_location(line, column, text.size)
        raise BetterHtml::HtmlError, s
      end

      def check_unquoted_value(type, start, stop, line, column)
        return if @config.allow_unquoted_attributes

        s = +"Unquoted attribute values are not allowed\n"
        s << build_location(line, column, stop - start)
        raise BetterHtml::HtmlError, s
      end

      def build_location(line, column, length)
        s = +"On line #{line} column #{column}:\n"
        s << "#{extract_line(line)}\n"
        s << "#{" " * column}#{"^" * length}"
      end

      def extract_line(line)
        line = @parser.document.lines[line - 1]
        line.nil? ? "" : line.gsub(/\n$/, "")
      end
    end
  end
end
