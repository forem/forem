module Ai
  class OrgPageCrawler
    VERSION = "1.1"

    def initialize(organization:, urls:)
      @organization = organization
      @urls = urls.select(&:present?).first(4)
    end

    def crawl
      page_texts = fetch_all_page_texts
      ai_extracted = extract_with_ai(page_texts)
      dev_posts = search_dev_posts

      {
        title: ai_extracted[:tagline],
        description: ai_extracted[:description],
        detected_color: ai_extracted[:brand_color],
        features: ai_extracted[:features],
        og_image: ai_extracted[:og_image],
        links: build_links,
        dev_posts: dev_posts
      }
    rescue StandardError => e
      Rails.logger.error("OrgPageCrawler failed: #{e.message}")
      { error: e.message, title: nil, description: nil, og_image: nil,
        links: [], detected_color: nil, dev_posts: search_dev_posts_safe }
    end

    private

    def fetch_all_page_texts
      @urls.filter_map do |url|
        html = fetch_html(url)
        next if html.blank?

        text = extract_text_from_html(html)
        { url: url, text: text.truncate(3000) }
      end
    end

    def extract_text_from_html(html)
      doc = Nokogiri::HTML(html)
      doc.css("script, style, nav, footer, header").remove
      doc.text.gsub(/\s+/, " ").strip
    end

    def extract_with_ai(page_texts)
      return {} if page_texts.blank?

      ai_client = Ai::Base.new(wrapper: self, affected_content: @organization)
      prompt = build_extraction_prompt(page_texts)
      response = ai_client.call(prompt)
      parse_extraction_response(response)
    rescue StandardError => e
      Rails.logger.warn("AI extraction failed, falling back to basic parsing: #{e.message}")
      fallback_extraction
    end

    def build_extraction_prompt(page_texts)
      pages_context = page_texts.map { |p| "URL: #{p[:url]}\nContent: #{p[:text]}" }.join("\n\n---\n\n")

      <<~PROMPT
        Analyze the following web pages for the organization "#{@organization.name}" and extract:

        1. tagline: A short, punchy tagline (under 80 chars) that captures what this org does
        2. description: A 1-2 sentence developer-friendly description of the organization
        3. brand_color: The organization's primary brand color as a hex code (e.g. #F22F46). Use your knowledge of well-known brands, or infer from the content.
        4. features: A JSON array of 3-5 key features/capabilities, each with "title" and "description" keys

        WEB PAGES:
        #{pages_context}

        Respond in EXACTLY this format (no other text):
        TAGLINE: <tagline>
        DESCRIPTION: <description>
        BRAND_COLOR: <hex color>
        FEATURES: <JSON array>
      PROMPT
    end

    def parse_extraction_response(response)
      return {} if response.blank?

      tagline = response[/TAGLINE:\s*(.+?)(?:\n|$)/i, 1]&.strip
      description = response[/DESCRIPTION:\s*(.+?)(?:\n|$)/i, 1]&.strip
      brand_color = response[/BRAND_COLOR:\s*(#[0-9A-Fa-f]{6})/i, 1]&.strip
      features_json = response[/FEATURES:\s*(\[.+\])/im, 1]

      features = begin
        JSON.parse(features_json) if features_json.present?
      rescue JSON::ParserError
        nil
      end

      {
        tagline: tagline,
        description: description,
        brand_color: brand_color,
        features: features || [],
        og_image: nil
      }
    end

    def fallback_extraction
      primary_url = @urls.first
      return {} if primary_url.blank?

      html = fetch_html(primary_url)
      page = MetaInspector.new(primary_url, document: html)

      {
        tagline: page.best_title,
        description: page.description,
        brand_color: page.meta_tags.dig("name", "theme-color")&.first,
        features: [],
        og_image: page.images.best
      }
    rescue StandardError
      {}
    end

    def fetch_html(url)
      Rails.cache.fetch("org_crawler:#{url}", expires_in: 15.minutes) do
        response = HTTParty.get(url,
                                headers: { "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})" },
                                timeout: 10)
        response&.body
      end
    end

    def build_links
      @urls.map do |url|
        { url: url, label: label_for_url(url) }
      end
    end

    def label_for_url(url)
      uri = URI.parse(url)
      path = uri.path.to_s.gsub(%r{^/|/$}, "")
      return "Website" if path.blank?

      path.split("/").first.capitalize
    rescue URI::InvalidURIError
      "Link"
    end

    def search_dev_posts
      articles_by_org = Article.published
        .where(organization_id: @organization.id)
        .order(positive_reactions_count: :desc)
        .limit(20)
        .select(:id, :title, :path, :positive_reactions_count, :comments_count, :published_at)

      articles_about = Article.published
        .where("title ILIKE ? OR cached_tag_list ILIKE ?", "%#{@organization.name}%", "%#{@organization.slug}%")
        .where.not(id: articles_by_org.map(&:id))
        .order(positive_reactions_count: :desc)
        .limit(10)
        .select(:id, :title, :path, :positive_reactions_count, :comments_count, :published_at)

      (articles_by_org + articles_about).map do |article|
        {
          id: article.id,
          title: article.title,
          path: article.path,
          reactions: article.positive_reactions_count,
          comments: article.comments_count,
          published_at: article.published_at&.iso8601
        }
      end
    end

    def search_dev_posts_safe
      search_dev_posts
    rescue StandardError
      []
    end

    def valid_hex?(color)
      color.present? && color.match?(/\A#[0-9A-Fa-f]{3,6}\z/)
    end
  end
end
