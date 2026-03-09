module Ai
  module LiquidTagGuide
    CACHE_KEY = "ai:liquid_tag_guide"
    CACHE_EXPIRY = 12.hours

    def self.guide_text
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRY) do
        build_guide
      end
    end

    def self.build_guide
      guide_path = Rails.root.join("app/views/pages/_editor_guide_text.en.html.erb")
      url_embeds_path = Rails.root.join("app/views/pages/_supported_url_embeds_list.en.html.erb")
      nonurl_embeds_path = Rails.root.join("app/views/pages/_supported_nonurl_embeds_list.en.html.erb")

      raw_guide = File.read(guide_path)
      raw_url_embeds = File.read(url_embeds_path)
      raw_nonurl_embeds = File.read(nonurl_embeds_path)

      clean_guide = strip_erb_and_html(raw_guide)

      clean_url_embeds = raw_url_embeds.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
        .gsub(/<ul[^>]*>/, "\n")
        .gsub("</ul>", "\n")
        .gsub(/<li[^>]*>/, "- ")
        .gsub("</li>", "\n")
        .gsub(/<h4[^>]*>/, "\n### ")
        .gsub("</h4>", "\n")
        .gsub(/<p[^>]*>/, "\n")
        .gsub("</p>", "\n")
        .gsub(%r{<br\s*/?>}, "\n")
        .gsub(/<[^>]+>/, "")
        .gsub(/\n\s*\n\s*\n+/, "\n\n").strip

      clean_nonurl_embeds = raw_nonurl_embeds.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
        .gsub(/<h4[^>]*>/, "\n### ")
        .gsub("</h4>", "\n")
        .gsub(/<p[^>]*>/, "\n")
        .gsub("</p>", "\n")
        .gsub(%r{<br\s*/?>}, "\n")
        .gsub(/<pre[^>]*>/, "\n```\n")
        .gsub("</pre>", "\n```\n")
        .gsub(/<code[^>]*>/, "`")
        .gsub("</code>", "`")
        .gsub(/<[^>]+>/, "")
        .gsub(/\n\s*\n\s*\n+/, "\n\n").strip

      <<~GUIDE
        #{clean_guide}

        Supported URL Embeds:
        #{clean_url_embeds}

        Supported Non-URL (Block) Embeds:
        #{clean_nonurl_embeds}
      GUIDE
    end

    def self.strip_erb_and_html(raw)
      content_without_erb = raw.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
      ActionView::Base.full_sanitizer.sanitize(content_without_erb).gsub(/\s+/, " ").strip
    end

    private_class_method :build_guide, :strip_erb_and_html
  end
end
