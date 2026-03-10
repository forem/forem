module Ai
  class OrgPageCrawler
    VERSION = "1.1"
    CRAWLER_MODEL = Ai::OrgPageGenerator::PLANNER_MODEL

    def initialize(organization:, urls:, page_type: "developer")
      @organization = organization
      @urls = urls.select(&:present?).first(4)
      @page_type = page_type
      @parsed_docs = {}
    end

    def crawl
      page_texts = fetch_all_page_texts
      ai_extracted = extract_with_ai(page_texts)
      dev_posts = search_dev_posts
      dev_comments = search_dev_comments
      og_image = extract_og_image
      youtube_urls = extract_youtube_from_pages
      content_images = extract_content_images

      {
        title: ai_extracted[:tagline],
        description: ai_extracted[:description],
        detected_color: ai_extracted[:brand_color],
        features: ai_extracted[:features],
        testimonials: ai_extracted[:testimonials] || [],
        og_image: og_image,
        links: build_links,
        dev_posts: dev_posts,
        dev_comments: dev_comments,
        youtube_urls: youtube_urls,
        content_images: content_images
      }
    rescue StandardError => e
      Rails.logger.error("OrgPageCrawler failed: #{e.message}")
      { error: e.message, title: nil, description: nil, og_image: nil,
        links: [], detected_color: nil, dev_posts: search_dev_posts_safe,
        dev_comments: [], youtube_urls: [], content_images: [] }
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

    def parsed_doc(url)
      @parsed_docs[url] ||= begin
        html = fetch_html(url)
        html.present? ? Nokogiri::HTML(html) : nil
      end
    end

    def extract_text_from_html(html)
      doc = Nokogiri::HTML(html)
      doc.css("script, style, nav, footer, header").remove
      doc.text.gsub(/\s+/, " ").strip
    end

    def extract_with_ai(page_texts)
      return {} if page_texts.blank?

      ai_client = Ai::Base.new(model: CRAWLER_MODEL, wrapper: self, affected_content: @organization)
      prompt = build_extraction_prompt(page_texts)
      response = ai_client.call(prompt, json_mode: true)
      parse_extraction_response(response)
    rescue StandardError => e
      Rails.logger.warn("AI extraction failed, falling back to basic parsing: #{e.message}")
      fallback_extraction
    end

    def build_extraction_prompt(page_texts)
      pages_context = page_texts.map { |p| "URL: #{p[:url]}\nContent: #{p[:text]}" }.join("\n\n---\n\n")

      page_type_hint = case @page_type
                        when "developer"
                          "This page is for DEVELOPERS. Focus the tagline and description on technical capabilities, APIs, SDKs, and developer tools. Extract features that developers care about."
                        when "marketing"
                          "This page is a MARKETING SHOWCASE. Focus the tagline and description on product value propositions and benefits. Extract features that highlight business value."
                        when "community"
                          "This page is a COMMUNITY HUB. Focus the tagline and description on community, collaboration, and shared learning. Extract features about community engagement."
                        when "talent"
                          "This page is for TALENT/CAREERS. Focus the tagline and description on team culture, engineering values, and why developers should join. Extract features about the work environment."
                        else
                          ""
                        end

      <<~PROMPT
        Analyze the following web pages for the organization "#{@organization.name}" and extract structured data.

        #{page_type_hint}

        WEB PAGES:
        #{pages_context}

        Return a JSON object with these fields:
        - "tagline": A short, punchy tagline (under 80 chars) that captures what this org does
        - "description": A 1-2 sentence developer-friendly description
        - "brand_color": Primary brand color as hex code (e.g. "#F22F46"). Use your knowledge of well-known brands.
        - "features": Array of 3-5 objects with "title" and "description" keys
        - "testimonials": Array of REAL quotes found on these pages, each with "text", "author", "role". ONLY include quotes ACTUALLY on the pages. Empty array if none found.
      PROMPT
    end

    def parse_extraction_response(response)
      return {} if response.blank?

      parsed = JSON.parse(response)
      {
        tagline: parsed["tagline"],
        description: parsed["description"],
        brand_color: parsed["brand_color"],
        features: parsed["features"] || [],
        testimonials: parsed["testimonials"] || [],
        og_image: nil
      }
    rescue JSON::ParserError => e
      Rails.logger.warn("AI extraction JSON parse failed: #{e.message}")
      {}
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

      name = ActiveRecord::Base.sanitize_sql_like(@organization.name)
      slug = ActiveRecord::Base.sanitize_sql_like(@organization.slug)
      articles_about = Article.published
        .where("title ILIKE ? OR cached_tag_list ILIKE ?", "%#{name}%", "%#{slug}%")
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

    def search_dev_comments
      search_term = ActiveRecord::Base.sanitize_sql_like(@organization.name)
      slug = ActiveRecord::Base.sanitize_sql_like(@organization.slug)

      results = Comment
        .where("comments.body_markdown ILIKE ? OR comments.body_markdown ILIKE ?", "%#{search_term}%", "%#{slug}%")
        .joins("INNER JOIN articles ON comments.commentable_id = articles.id AND comments.commentable_type = 'Article'")
        .where("articles.published = ?", true)
        .where("comments.score >= ?", 0)
        .order(positive_reactions_count: :desc)
        .limit(10)
        .map do |comment|
          {
            id: comment.id,
            id_code: comment.id_code_generated,
            path: comment.path,
            author: comment.user.username,
            reactions: comment.positive_reactions_count,
            excerpt: comment.body_markdown.truncate(100)
          }
        end

      before_sentiment = results.length
      results = results.reject { |c| c[:excerpt].match?(/\b(hate|worst|terrible|awful|sucks|garbage|trash|broken|useless|avoid|don'?t use|do not use|bug|issue|problem|disappointed|frustrat)/i) }
      Rails.logger.info("OrgPageCrawler sentiment filter removed #{before_sentiment - results.length} comments, returning #{results.first(5).length}")

      results.first(5)
    rescue StandardError => e
      Rails.logger.warn("Comment search failed: #{e.message}\n#{e.backtrace&.first(3)&.join("\n")}")
      []
    end

    def extract_youtube_from_pages
      urls = []
      @urls.each do |url|
        html = fetch_html(url)
        next if html.blank?

        html.scan(%r{https?://(?:www\.)?(?:youtube\.com/watch\?v=[\w-]+|youtu\.be/[\w-]+)}).each do |yt_url|
          urls << yt_url
        end
      end
      urls.uniq.first(3)
    rescue StandardError
      []
    end

    def extract_content_images
      images = []
      @urls.each do |url|
        doc = parsed_doc(url)
        next if doc.nil?

        doc.css("img").each do |img|
          src = img["src"]
          next unless src&.start_with?("http")
          next if src.match?(/logo|icon|avatar|favicon|badge|shield|tracking|pixel/i)

          alt = img["alt"].to_s.strip
          title = img.ancestors("figure").first&.at_css("figcaption")&.text&.strip || alt
          next if alt.blank? && title.blank?

          images << { url: src, alt: alt, title: title.truncate(80) }
          break if images.length >= 6
        end
        break if images.length >= 6
      end
      images
    rescue StandardError
      []
    end

    def extract_og_image
      @urls.each do |url|
        doc = parsed_doc(url)
        next if doc.nil?

        og = doc.at_css('meta[property="og:image"]')&.attr("content")
        return og if og.present? && og.start_with?("http")

        twitter = doc.at_css('meta[name="twitter:image"]')&.attr("content")
        return twitter if twitter.present? && twitter.start_with?("http")
      end
      nil
    rescue StandardError
      nil
    end

  end
end
