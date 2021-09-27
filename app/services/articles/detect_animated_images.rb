module Articles
  module DetectAnimatedImages
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

    # FastImage will use this number both for read and open timeout
    TIMEOUT = 10

    def self.call(article)
      parsed_html = Nokogiri::HTML.fragment(article.processed_html)

      # we ignore images contained in liquid tags as they are not animated
      images = parsed_html.css("img") - parsed_html.css(IMAGES_IN_LIQUID_TAGS_SELECTORS)

      found = false
      images.each do |img|
        src = img.attr("src")
        next unless src

        image = if URI.parse(src).relative?
                  retrieve_image_from_uploader_store(src)
                else
                  src
                end

        next if image.blank?
        next unless FastImage.animated?(image, timeout: TIMEOUT)

        img["data-animated"] = true
        found = true
      end

      article.update_columns(processed_html: parsed_html.to_html) if found
    end

    def self.retrieve_image_from_uploader_store(src)
      filename = File.basename(src)
      uploader = ArticleImageUploader.new
      uploader.retrieve_from_store!(filename)

      return unless uploader.file.exists?

      uploader.file&.file
    end
    private_class_method :retrieve_image_from_uploader_store
  end
end
