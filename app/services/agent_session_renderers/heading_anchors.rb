module AgentSessionRenderers
  # Gives the headings of one transcript message ids scoped to its embed, and
  # points that message's own "#fragment" links (e.g. an agent-written table of
  # contents) at them.
  #
  # Slugs follow GitHub's convention, which is what coding agents generate:
  # lowercase, punctuation dropped, hyphens kept, spaces become hyphens, and
  # repeated headings get "-1", "-2", ... suffixes.
  class HeadingAnchors
    SLUG_DISALLOWED = /[^\p{L}\p{M}\p{N}\p{Pc}\- ]/
    FRAGMENT_HREF = /href="#([^"]+)"/

    def self.slugify(heading_html)
      text = CGI.unescapeHTML(heading_html.to_s.gsub(/<[^>]*>/, ""))
      text.strip.downcase.gsub(SLUG_DISALLOWED, "").tr(" ", "-")
    end

    # prefix must be unique per message within the page, e.g.
    # "agent-session-12-3" for message 3 of session 12.
    def initialize(prefix)
      @prefix = prefix
      @ids_by_slug = {}
    end

    # Returns the id for a heading, or nil when it has no letters or digits.
    def register(heading_html)
      base = self.class.slugify(heading_html)
      return unless base.match?(/[\p{L}\p{N}]/)

      slug = base
      suffix = 0
      slug = "#{base}-#{suffix += 1}" while @ids_by_slug.key?(slug)
      @ids_by_slug[slug] = "#{@prefix}-#{slug}"
    end

    # Rewrites href="#slug" to the scoped id when the slug is a heading of this
    # message. Other fragment links are left untouched.
    def link_fragments(html)
      html.gsub(FRAGMENT_HREF) do |match|
        fragment = Addressable::URI.unencode_component(CGI.unescapeHTML(Regexp.last_match(1)))
        id = @ids_by_slug[fragment] || @ids_by_slug[fragment.downcase]
        id ? %(href="##{ERB::Util.html_escape(id)}") : match
      end
    end
  end
end
