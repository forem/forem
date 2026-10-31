module Articles
  # Opt-in inline formatting for Quickie (status post) titles.
  #
  # Supported syntax (single line only, unmatched markers stay literal text):
  #   **bold**   *italic* or _italic_   __underline__   [text](https://example.com)
  #
  # The formatter works on text that is *already HTML-escaped* and is wrapped around the
  # existing renderer: formatted spans are swapped for opaque placeholders before the base
  # renderer (paragraphs, line breaks, URL shortening) runs, and swapped back afterwards.
  # The only HTML it can emit is the fixed tags below, built from escaped text, so no
  # user-supplied markup reaches the page. Text without any formatting is returned
  # untouched, so plain-text Quickies render exactly as before.
  #
  #   Articles::QuickieFormatter.render(escaped_title, links: false) do |prepared|
  #     base_renderer(prepared)
  #   end
  class QuickieFormatter
    PLACEHOLDER_OPEN = "".freeze
    PLACEHOLDER_CLOSE = "".freeze
    PLACEHOLDER_CHARACTERS = /[]/
    PLACEHOLDER = /(\d+)/
    FORMATTING_HINT = /[*_\[]/

    LINK = %r{\[([^\[\]\n]{1,100})\]\((https?://[^\s<>"{}|\\^`\[\]()]+)\)}
    INLINE_RULES = [
      [/\*\*(?=[^\s*])(.*?[^\s*])\*\*/, "strong"],
      [/(?<![[:word:]_])__(?=[^\s_])(.*?[^\s_])__(?![[:word:]_])/, "u"],
      [/(?<![[:word:]*])\*(?=[^\s*])([^*\n]*[^\s*])\*(?![[:word:]*])/, "em"],
      [/(?<![[:word:]_])_(?=[^\s_])([^_\n]*[^\s_])_(?![[:word:]_])/, "em"],
    ].freeze
    LINK_REL = "nofollow noopener noreferrer ugc".freeze
    LINK_FALLBACK_STYLE = "text-decoration: underline;".freeze

    # @param escaped_text [String] the title with `<` and `>` already escaped
    # @param links [Boolean] true renders real anchors; false renders underlined spans, for
    #   places where the title is already inside a link (feed cards) and anchors can't nest
    def self.render(escaped_text, links: false)
      formatter = new(links: links)
      html = yield formatter.prepare(escaped_text)
      formatter.restore(html)
    end

    def initialize(links: false)
      @links = links
      @tokens = []
    end

    # Returns the text with formatted spans replaced by placeholders, or the original text
    # when there is nothing to format.
    def prepare(text)
      return text unless text.valid_encoding? && text.match?(FORMATTING_HINT)

      prepared = replace_inline(replace_links(text.gsub(PLACEHOLDER_CHARACTERS, "")))
      @tokens.empty? ? text : prepared
    end

    # Puts the formatted HTML back in place of the placeholders.
    def restore(html)
      return html if @tokens.empty?

      restored = String.new(html)
      # Tokens can contain placeholders of the tokens nested inside them (bold around italic).
      restored = restored.gsub(PLACEHOLDER) { @tokens[Regexp.last_match(1).to_i] } while restored.match?(PLACEHOLDER)
      restored.gsub(PLACEHOLDER_CHARACTERS, "")
    end

    private

    def replace_links(text)
      text.gsub(LINK) do
        label = Regexp.last_match(1)
        url = Regexp.last_match(2)
        stash(link_html(replace_inline(label), url))
      end
    end

    def replace_inline(text)
      INLINE_RULES.reduce(text) do |current, (pattern, tag)|
        current.gsub(pattern) do
          inner = Regexp.last_match(1)
          stash("<#{tag}>#{replace_inline(inner)}</#{tag}>")
        end
      end
    end

    def link_html(label, url)
      return %(<span style="#{LINK_FALLBACK_STYLE}">#{label}</span>) unless @links

      %(<a href="#{url.gsub('&', '&amp;')}" target="_blank" rel="#{LINK_REL}">#{label}</a>)
    end

    def stash(html)
      @tokens << html
      "#{PLACEHOLDER_OPEN}#{@tokens.size - 1}#{PLACEHOLDER_CLOSE}"
    end
  end
end
