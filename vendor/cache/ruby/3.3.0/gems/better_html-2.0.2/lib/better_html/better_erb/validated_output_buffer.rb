# frozen_string_literal: true

module BetterHtml
  class BetterErb
    class ValidatedOutputBuffer
      class Context
        def initialize(output, context, code, auto_escape)
          @output = output
          @context = context
          @code = code
          @auto_escape = auto_escape
        end

        def safe_quoted_value_append=(value)
          return if value.nil?

          value = properly_escaped(value)

          if value.include?(@context[:quote_character])
            raise UnsafeHtmlError, "Detected invalid characters as part of the interpolation "\
              "into a quoted attribute value. The value cannot contain the character #{@context[:quote_character]}."
          end

          @output.safe_append = value
        end

        def safe_unquoted_value_append=(value)
          raise DontInterpolateHere, "Do not interpolate without quotes around this "\
            "attribute value. Instead of "\
            "<#{@context[:tag_name]} #{@context[:attribute_name]}=#{@context[:attribute_value]}<%=#{@code}%>> "\
            "try <#{@context[:tag_name]} #{@context[:attribute_name]}=\"#{@context[:attribute_value]}<%=#{@code}%>\">."
        end

        def safe_space_after_attribute_append=(value)
          raise DontInterpolateHere, "Add a space after this attribute value. Instead of "\
            "<#{@context[:tag_name]} #{@context[:attribute_name]}=\"#{@context[:attribute_value]}\"<%=#{@code}%>> "\
            "try <#{@context[:tag_name]} #{@context[:attribute_name]}=\"#{@context[:attribute_value]}\" <%=#{@code}%>>."
        end

        def safe_attribute_name_append=(value)
          return if value.nil?

          value = value.to_s

          unless value =~ /\A[a-z0-9\-]*\z/
            raise UnsafeHtmlError, "Detected invalid characters as part of the interpolation "\
              "into a attribute name around '#{@context[:attribute_name]}<%=#{@code}%>'."
          end

          @output.safe_append = value
        end

        def safe_after_attribute_name_append=(value)
          return if value.nil?

          unless value.is_a?(BetterHtml::HtmlAttributes)
            raise DontInterpolateHere, "Do not interpolate #{value.class} in a tag. "\
              "Instead of <#{@context[:tag_name]} <%=#{@code}%>> please "\
              "try <#{@context[:tag_name]} <%= html_attributes(attr: value) %>>."
          end

          @output.safe_append = value.to_s
        end

        def safe_after_equal_append=(value)
          raise DontInterpolateHere, "Do not interpolate without quotes after "\
            "attribute around '#{@context[:attribute_name]}=<%=#{@code}%>'."
        end

        def safe_tag_append=(value)
          return if value.nil?

          unless value.is_a?(BetterHtml::HtmlAttributes)
            raise DontInterpolateHere, "Do not interpolate #{value.class} in a tag. "\
              "Instead of <#{@context[:tag_name]} <%=#{@code}%>> please "\
              "try <#{@context[:tag_name]} <%= html_attributes(attr: value) %>>."
          end

          @output.safe_append = value.to_s
        end

        def safe_tag_name_append=(value)
          return if value.nil?

          value = value.to_s

          unless value =~ /\A[a-z0-9\:\-]*\z/
            raise UnsafeHtmlError, "Detected invalid characters as part of the interpolation "\
              "into a tag name around: <#{@context[:tag_name]}<%=#{@code}%>>."
          end

          @output.safe_append = value
        end

        def safe_rawtext_append=(value)
          return if value.nil?

          value = properly_escaped(value)

          if @context[:tag_name].downcase == "script" &&
              (value =~ /<script/i || value =~ %r{</script}i)
            # https://www.w3.org/TR/html5/scripting-1.html#restrictions-for-contents-of-script-elements
            raise UnsafeHtmlError, "Detected invalid characters as part of the interpolation "\
              "into a script tag around: <#{@context[:tag_name]}>#{@context[:rawtext_text]}<%=#{@code}%>. "\
              "A script tag cannot contain <script or </script anywhere inside of it."
          elsif value =~ /<#{Regexp.escape(@context[:tag_name].downcase)}/i ||
              value =~ %r{</#{Regexp.escape(@context[:tag_name].downcase)}}i
            raise UnsafeHtmlError, "Detected invalid characters as part of the interpolation "\
              "into a #{@context[:tag_name].downcase} tag around: " \
              "<#{@context[:tag_name]}>#{@context[:rawtext_text]}<%=#{@code}%>."
          end

          @output.safe_append = value
        end

        def safe_comment_append=(value)
          return if value.nil?

          value = properly_escaped(value)

          # in a <!-- ...here --> we disallow -->
          if value =~ /-->/
            raise UnsafeHtmlError, "Detected invalid characters as part of the interpolation "\
              "into a html comment around: <!--#{@context[:comment_text]}<%=#{@code}%>."
          end

          @output.safe_append = value
        end

        def safe_none_append=(value)
          return if value.nil?

          @output.safe_append = properly_escaped(value)
        end

        private

        def properly_escaped(value)
          if value.is_a?(ValidatedOutputBuffer)
            # in html context, never escape a ValidatedOutputBuffer
            value.to_s
          elsif @auto_escape
            # in html context, follow auto_escape rule
            auto_escape_html_safe_value(value.to_s)
          else
            value.to_s
          end
        end

        def auto_escape_html_safe_value(arg)
          arg.html_safe? ? arg : CGI.escapeHTML(arg).html_safe
        end
      end

      class << self
        def wrap(output, context, code, auto_escape)
          Context.new(output, context, code, auto_escape)
        end
      end

      def html_safe?
        true
      end

      def html_safe
        self.class.new(@output)
      end

      def to_s
        @output.html_safe
      end
    end
  end
end
