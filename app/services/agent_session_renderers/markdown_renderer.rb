module AgentSessionRenderers
  class MarkdownRenderer
    ALLOWED_TAGS = %w[p br strong em b i code pre span a ul ol li h1 h2 h3 h4 h5 h6 blockquote div table thead tbody tr th td hr].freeze
    ALLOWED_ATTRS = %w[class href target rel id].freeze

    # Redcarpet renderer that adds anchor ids to headings. Agent transcripts
    # frequently include a table of contents with fragment links (e.g.
    # "[Intro](#intro)"); without heading ids those links render dead inside
    # the embed. Ids are prefixed with a per-session scope so they cannot
    # collide with the ids of the article embedding the session (or with
    # another session's embed on the same page).
    class HTMLWithHeadingIds < Redcarpet::Render::HTML
      def initialize(scope: nil, used_ids: {})
        super(hard_wrap: true, escape_html: true)
        @scope = scope
        @used_ids = used_ids
      end

      def header(text, header_level)
        return %(<h#{header_level}>#{text}</h#{header_level}>) if @scope.blank?

        anchor = "#{@scope}-#{slugify(text)}"
        if @used_ids.key?(anchor)
          @used_ids[anchor] += 1
          anchor = "#{anchor}-#{@used_ids[anchor] + 1}"
        else
          @used_ids[anchor] = 0
        end
        %(<h#{header_level} id="#{anchor}">#{text}</h#{header_level}>)
      end

      private

      # GitHub-style slug (lowercase, punctuation removed except hyphens,
      # whitespace collapsed to single hyphens). Coding agents generate
      # table-of-contents fragment links in this convention (e.g.
      # "#work-through-a-small-business-example"), so the renderer must slug
      # headings the same way for those links to resolve. This intentionally
      # differs from Redcarpet::Render::HTMLRouge#header's article slugify,
      # which strips hyphens as punctuation.
      def slugify(string)
        stripped_string = ActionView::Base.full_sanitizer.sanitize string
        stripped_string.downcase.gsub(EmojiRegex::RGIEmoji, "").strip
                             .gsub(/[^\p{L}\p{N}\s-]/, "").gsub(/\s+/, "-")
      end
    end

    def self.render(text, scope: nil, used_ids: {})
      return "".html_safe if text.blank?

      renderer = HTMLWithHeadingIds.new(scope: scope, used_ids: used_ids)
      markdown = Redcarpet::Markdown.new(renderer,
                                         fenced_code_blocks: true,
                                         autolink: true,
                                         no_intra_emphasis: true,
                                         strikethrough: true,
                                         tables: true)

      html = markdown.render(text)

      # Syntax-highlight fenced code blocks via Rouge
      html = highlight_code_blocks(html)

      # Style [REDACTED] markers
      html = html.gsub("[REDACTED]", '<span class="agent-session-redacted">[REDACTED]</span>')

      # Point fragment links (e.g. a transcript table of contents) at the
      # scoped heading ids rendered above, but only when the target heading
      # actually exists in this block.
      html = rewrite_fragment_links(html, scope) if scope

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

    # Rewrites `href="#slug"` links to `href="#<scope>-slug"` when a heading
    # with the scoped id exists in the same rendered block. Links without a
    # matching heading are left untouched.
    def self.rewrite_fragment_links(html, scope)
      html.gsub(/href="([^"]+)"/) do
        href = Regexp.last_match(1)
        next %(href="#{href}") unless href.start_with?("#")

        scoped_href = "##{scope}-#{href.delete_prefix('#')}"
        html.include?(%(id="#{scope}-#{href.delete_prefix('#')}")) ? %(href="#{scoped_href}") : %(href="#{href}")
      end
    end
  end
end
