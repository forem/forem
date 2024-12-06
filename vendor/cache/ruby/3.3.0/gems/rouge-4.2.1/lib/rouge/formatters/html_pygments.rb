# frozen_string_literal: true

module Rouge
  module Formatters
    class HTMLPygments < Formatter
      def initialize(inner, css_class='codehilite')
        @inner = inner
        @css_class = css_class
      end

      def stream(tokens, &b)
        yield %(<div class="highlight"><pre class="#{@css_class}"><code>)
        @inner.stream(tokens, &b)
        yield "</code></pre></div>"
      end
    end
  end
end
