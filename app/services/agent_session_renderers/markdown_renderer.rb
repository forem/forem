module AgentSessionRenderers
  class MarkdownRenderer
    ALLOWED_TAGS = %w[p br strong em b i code pre span a ul ol li h1 h2 h3 h4 h5 h6 blockquote div table thead tbody tr th td hr].freeze
    # `id` is only ever emitted by HeadingRenderer below, always prefixed with
    # the embed scope: raw HTML in transcripts is escaped (escape_html: true).
    ALLOWED_ATTRS = %w[class href target rel id].freeze

    # Adds scoped ids to headings when given a HeadingAnchors instance.
    class HeadingRenderer < Redcarpet::Render::HTML
      attr_accessor :heading_anchors

      def header(text, header_level)
        id = heading_anchors&.register(text)
        id_attr = id ? %( id="#{ERB::Util.html_escape(id)}") : ""
        "<h#{header_level}#{id_attr}>#{text}</h#{header_level}>\n"
      end
    end

    # heading_anchors: an AgentSessionRenderers::HeadingAnchors scoped to the
    # message being rendered. Without it headings get no ids, as before.
    def self.render(text, heading_anchors: nil)
      return "".html_safe if text.blank?

      renderer = HeadingRenderer.new(
        hard_wrap: true,
        escape_html: true,
      )
      renderer.heading_anchors = heading_anchors
      markdown = Redcarpet::Markdown.new(renderer,
                                         fenced_code_blocks: true,
                                         autolink: true,
                                         no_intra_emphasis: true,
                                         strikethrough: true,
                                         tables: true)

      html = markdown.render(text)

      # Point the message's own "#slug" links (e.g. a table of contents) at its headings
      html = heading_anchors.link_fragments(html) if heading_anchors

      # Syntax-highlight fenced code blocks via Rouge
      html = highlight_code_blocks(html)

      # Style [REDACTED] markers
      html = html.gsub("[REDACTED]", '<span class="agent-session-redacted">[REDACTED]</span>')

      sanitizer = Rails::HTML5::SafeListSanitizer.new
      sanitizer.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS).html_safe
    end

    # Take the plain <pre><code class="LANG"> blocks from Redcarpet and run them through Rouge
    def self.highlight_code_blocks(html)
      html.gsub(%r{<pre><code class="(\w+)">(.*?)</code></pre>}m) do
        lang = Regexp.last_match(1)
        code = CGI.unescapeHTML(Regexp.last_match(2))
        begin
          lexer = Rouge::Lexer.find(lang) || Rouge::Lexers::PlainText.new
          formatter = Rouge::Formatters::HTML.new
          highlighted = formatter.format(lexer.lex(code))
          %(<pre class="highlight #{lang}"><code>#{highlighted}</code></pre>)
        rescue StandardError
          %(<pre class="highlight"><code>#{CGI.escapeHTML(code)}</code></pre>)
        end
      end.gsub(%r{<pre><code>(.*?)</code></pre>}m) do
        # Un-tagged code blocks get plain highlight class
        code = Regexp.last_match(1)
        %(<pre class="highlight"><code>#{code}</code></pre>)
      end
    end
  end
end
