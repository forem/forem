module Articles
  module EnrichImageAttributes
    IMAGES_IN_LIQUID_TAGS_SELECTORS = [
      ".liquid-comment img", # CommentTag
      ".ltag-github-readme-tag img", # GithubReadmeTag
      ".ltag__link__pic img", # LinkTag and MediumTag profile pic
      ".ltag__link__servicename img", # MediumTag
      ".ltag__link__taglist img", # LinkTag
      ".ltag__reddit--container img", # RedditTag
      ".ltag__stackexchange--container img", # StackexchangeTag
      ".ltag__twitter-tweet img", # TweetTag
      ".ltag__user img", # UserTag and OrganizationTag
      ".ltag__user-subscription-tag img", # UserSubscriptionTag
      ".ltag_github-liquid-tag img", # GitHubIssueTag
      ".podcastliquidtag img", # PodcastTag
    ].join(", ").freeze

    def self.call(article)
      fast_image_headers = { "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})" }
      store_image_if_appropriate(article)
      parsed_html = Nokogiri::HTML.fragment(article.processed_html)
      main_image_height = default_image_height

      # we ignore images contained in liquid tags as they are not animated
      images = parsed_html.css("img") - parsed_html.css(IMAGES_IN_LIQUID_TAGS_SELECTORS)
      return unless images.any? || article.main_image

      images.each do |img|
        src = img.attr("src")
        next unless src

        image = if URI.parse(src).relative?
                  retrieve_image_from_uploader_store(src)
                else
                  src
                end

        next if image.blank?

        img_properties = FastImage.new(image, timeout: 10, http_header: fast_image_headers)
        img["width"], img["height"] = img_properties.size
        img["data-animated"] = true if img_properties.type == :gif
      end

      if article.main_image && Settings::UserExperience.cover_image_fit(subforem_id: article.subforem_id) == "limit"
        main_image_size = FastImage.size(article.main_image, timeout: 15, http_header: fast_image_headers)
        main_image_height = (main_image_size[1].to_f / main_image_size[0]) * 1000 if main_image_size
      end

      article.update_columns(processed_html: parsed_html.to_html, main_image_height: main_image_height)
    end

    def self.retrieve_image_from_uploader_store(src)
      filename = File.basename(src)
      uploader = ArticleImageUploader.new
      uploader.retrieve_from_store!(filename)

      return unless uploader.file.exists?

      uploader.file&.file
    end
    private_class_method :retrieve_image_from_uploader_store

    def self.default_image_height
      # If FastImage times out, we don't want to fall back to the "max limit" — 300 is instead used as a safer default
      # This will ultimately represent the height the image takes over *while it loads*.
      # FastImage will reliably succeed. This is a fallback.
      Settings::UserExperience.cover_image_fit == "limit" ? 300 : Settings::UserExperience.cover_image_height
    end
    private_class_method :default_image_height

    def self.store_image_if_appropriate(article)
      return if ApplicationConfig["AWS_BUCKET_NAME"].blank?

      markdown_text = article.body_markdown
      markdown_pattern = /!\[.*?\]\((.*?)\)/
      html_pattern = /<img.*?src=["'](.*?)["']/
      markdown_urls = markdown_text.scan(markdown_pattern).flatten
      html_urls = markdown_text.scan(html_pattern).flatten
      all_urls = markdown_urls + html_urls
      stored_image_url = "https://#{ApplicationConfig['AWS_BUCKET_NAME']}.s3.amazonaws.com"
      filtered_urls = all_urls.reject { |url| url.include?(stored_image_url) }
      images_converted = []
      filtered_urls.uniq.each do |url|
        store = MediaStore.where(original_url: url).first_or_create
        images_converted << store.output_url if store&.created_at&.> 1.minute.ago
      rescue StandardError => e
        Rails.logger.error("Error storing images: #{e.message}")
      end
      # This just updates the processed HTML based on new state (now has media stores)
      article.evaluate_and_update_column_from_markdown if images_converted.any?
    rescue StandardError => e
      Rails.logger.error("Error storing images: #{e.message}")
    end
    private_class_method :store_image_if_appropriate
  end
end
