require "rouge"

module BetterErrors
  # @private
  class CodeFormatter::HTML < CodeFormatter
    def source_unavailable
      "<p class='unavailable'>Source is not available</p>"
    end

    def formatted_lines
      each_line_of(highlighted_lines) { |highlight, current_line, str|
        class_name = highlight ? "highlight" : ""
        sprintf '<pre class="%s">%s</pre>', class_name, str
      }
    end

    def formatted_nums
      each_line_of(highlighted_lines) { |highlight, current_line, str|
        class_name = highlight ? "highlight" : ""
        sprintf '<span class="%s">%5d</span>', class_name, current_line
      }
    end

    def formatted_code
      %{
        <div class="code_linenums">#{formatted_nums.join}</div>
        <div class="code"><div class='code-wrapper'>#{super}</div></div>
      }
    end

    def rouge_lexer
      Rouge::Lexer.guess(filename: filename, source: source) { Rouge::Lexers::Ruby }
    end

    def highlighted_lines
      Rouge::Formatters::HTML.new.format(rouge_lexer.lex(context_lines.join)).lines
    end

  end
end
