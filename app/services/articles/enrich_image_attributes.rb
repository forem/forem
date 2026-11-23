module Articles
  module EnrichImageAttributes
    INSPECTION_BUDGET_SECONDS = 30

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

    # Enriches <img> tags in article.processed_html with width, height, and
    # data-animated attributes and computes article.main_image_height.
    def self.call(article)
      fast_image_headers = { "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})" }
      store_image_if_appropriate(article)
      processed_html = article.processed_html
      parsed_html, images = extract_enrichable_images(processed_html)
      return unless images.any? || article.main_image

      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + INSPECTION_BUDGET_SECONDS
      images.each do |img|
        remaining = [deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), 10].min
        break if remaining <= 0

        src = img.attr("src")
        next if src.blank?

        begin
          parsed_src = URI.parse(src)
        rescue URI::InvalidURIError
          next
        end

        img_properties = inspect_image(src, parsed_src, fast_image_headers, timeout: remaining)
        next unless img_properties

        img["width"], img["height"] = img_properties.size
        img["data-animated"] = true if img_properties.type == :gif
      end

      updated_html = images.any? ? parsed_html.to_html : processed_html
      main_image_timeout = [deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), 15].min
      article.update_columns(
        processed_html: updated_html,
        main_image_height: resolve_main_image_height(article, fast_image_headers, timeout: main_image_timeout),
      )
    end

    def self.inspect_image(src, parsed_src, fast_image_headers, timeout: 10)
      if parsed_src.relative?
        image, is_local_file = retrieve_image_from_uploader_store(src)
        return if image.blank?

        return SafeFastImage.from_file(image) if is_local_file

        return SafeFastImage.new(image, timeout: timeout, http_header: fast_image_headers)
      end

      SafeFastImage.new(src, timeout: timeout, http_header: fast_image_headers)
    end
    private_class_method :inspect_image

    def self.resolve_main_image_height(article, fast_image_headers, timeout: 15)
      return 500 if article.main_image&.include?("ytimg.com") # Hardcoded for 1000/500

      if article.main_image && Settings::UserExperience.cover_image_fit(subforem_id: article.subforem_id) == "limit"
        main_image_size = SafeFastImage.size(article.main_image, timeout: timeout, http_header: fast_image_headers)
        return (main_image_size[1].to_f / main_image_size[0]) * 1000 if main_image_size
      end

      default_image_height
    end
    private_class_method :resolve_main_image_height

    def self.extract_enrichable_images(processed_html)
      return [nil, []] unless processed_html&.match?(/<img/i)

      parsed_html = Nokogiri::HTML.fragment(processed_html)
      all_images = parsed_html.css("img")
      # we ignore images contained in liquid tags as they are not animated
      images = if all_images.any? && may_contain_liquid_tag_images?(processed_html)
                 all_images - parsed_html.css(IMAGES_IN_LIQUID_TAGS_SELECTORS)
               else
                 all_images
               end
      [parsed_html, images]
    end
    private_class_method :extract_enrichable_images

    def self.may_contain_liquid_tag_images?(html)
      html.include?("ltag") || html.include?("liquid-comment") ||
        html.include?("podcastliquidtag") || html.include?("&")
    end
    private_class_method :may_contain_liquid_tag_images?

    def self.retrieve_image_from_uploader_store(src)
      filename = File.basename(src)
      uploader = ArticleImageUploader.new
      uploader.retrieve_from_store!(filename)

      return [nil, false] unless uploader.file.exists?

      # Local storage yields a SanitizedFile whose path SafeFastImage.from_file can read directly,
      # but remote (fog) storage has no local file, so hand SafeFastImage the stored image's URL.
      if uploader.file.is_a?(CarrierWave::SanitizedFile)
        [uploader.file.file, true]
      else
        [uploader.url, false]
      end
    end
    private_class_method :retrieve_image_from_uploader_store

    def self.default_image_height
      # If FastImage times out, we don't want to fall back to the "max limit" — 300 is instead used as a safer default
      # This will ultimately represent the height the image takes over *while it loads*.
      # FastImage will reliably succeed. This is a fallback.
      Settings::UserExperience.cover_image_fit == "limit" ? 300 : Settings::UserExperience.cover_image_height
    end
    private_class_method :default_image_height

    # Extracts external images from article.body_markdown, stores them in
    # MediaStore, and re-renders the article's processed_html when new images are stored.
    def self.store_image_if_appropriate(article)
      bucket = ApplicationConfig["AWS_BUCKET_NAME"]
      return if bucket.blank?

      markdown_text = article.body_markdown.to_s
      return if markdown_text.blank?

      stored_image_url = "https://#{bucket}.s3.amazonaws.com"
      raw_urls = ForemNative.extract_markdown_and_html_image_urls(markdown_text, stored_image_url) ||
        legacy_extract_image_urls(markdown_text, stored_image_url)
      filtered_urls = ArticleImageUploader.normalize_external_image_urls(raw_urls, bucket)
      return if filtered_urls.empty?

      images_converted = []
      filtered_urls.each do |url|
        store = MediaStore.where(original_url: url).first_or_create
        images_converted << store.output_url if store&.persisted? && store.created_at&.after?(1.minute.ago)
      rescue StandardError => e
        Rails.logger.error("Error storing images: #{e.message}")
      end
      # This just updates the processed HTML based on new state (now has media stores)
      article.evaluate_and_update_column_from_markdown if images_converted.any?
    rescue StandardError => e
      Rails.logger.error("Error storing images: #{e.message}")
    end
    private_class_method :store_image_if_appropriate

    def self.legacy_extract_image_urls(markdown_text, stored_image_url)
      markdown_pattern = /!\[.*?\]\((.*?)\)/
      html_pattern = /<img.*?src=["'](.*?)["']/
      markdown_urls = markdown_text.scan(markdown_pattern).flatten
      html_urls = markdown_text.scan(html_pattern).flatten
      all_urls = markdown_urls + html_urls
      all_urls.reject { |url| url.include?(stored_image_url) }.uniq
    end
    private_class_method :legacy_extract_image_urls
  end
end
