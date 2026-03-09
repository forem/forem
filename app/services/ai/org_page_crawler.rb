module Ai
  class OrgPageCrawler
    VERSION = "1.0"

    def initialize(organization:, urls:)
      @organization = organization
      @urls = urls.select(&:present?).first(4)
    end

    def crawl
      site_data = crawl_primary_url
      dev_posts = search_dev_posts
      detected_color = detect_brand_color(site_data)

      {
        title: site_data[:title],
        description: site_data[:description],
        og_image: site_data[:og_image],
        links: build_links,
        detected_color: detected_color,
        dev_posts: dev_posts
      }
    rescue StandardError => e
      Rails.logger.error("OrgPageCrawler failed: #{e.message}")
      { error: e.message, title: nil, description: nil, og_image: nil,
        links: [], detected_color: nil, dev_posts: search_dev_posts_safe }
    end

    private

    def crawl_primary_url
      primary_url = @urls.first
      return {} if primary_url.blank?

      html = fetch_html(primary_url)
      page = MetaInspector.new(primary_url, document: html)

      {
        title: page.best_title,
        description: page.description,
        og_image: page.images.best,
        meta_tags: page.meta_tags
      }
    rescue StandardError => e
      Rails.logger.warn("Failed to crawl #{@urls.first}: #{e.message}")
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

    def detect_brand_color(site_data)
      # Try meta theme-color first
      color = extract_theme_color(site_data[:meta_tags])
      return color if valid_hex?(color)

      # Try OG image dominant color via MiniMagick
      color = detect_from_image(site_data[:og_image])
      return color if valid_hex?(color)

      nil
    end

    def extract_theme_color(meta_tags)
      return nil if meta_tags.blank?

      meta_tags.dig("name", "theme-color")&.first
    rescue StandardError
      nil
    end

    def detect_from_image(image_url)
      return nil if image_url.blank?

      tempfile = Tempfile.new(["og_image", ".png"])
      begin
        response = HTTParty.get(image_url, timeout: 5)
        return nil unless response.success?

        tempfile.binmode
        tempfile.write(response.body)
        tempfile.rewind

        image = MiniMagick::Image.new(tempfile.path)
        image.resize "1x1"
        pixel = image.get_pixels.first&.first
        return nil unless pixel

        "#%02X%02X%02X" % pixel
      rescue StandardError => e
        Rails.logger.debug("Brand color detection from image failed: #{e.message}")
        nil
      ensure
        tempfile.close
        tempfile.unlink
      end
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
