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

    def self.call(article)
      parsed_html = Nokogiri::HTML.fragment(article.processed_html)

      # we ignore images contained in liquid tags as they are not animated
      images = parsed_html.css("img") - parsed_html.css(IMAGES_IN_LIQUID_TAGS_SELECTORS)

      found = false
      images.each do |img|
        src = img.attr("src")
        next unless src
        next unless FastImage.animated?(parsed_src(src))

        img["data-animated"] = true
        found = true
      end

      article.update_columns(processed_html: parsed_html.to_html) if found
    end

    def self.parsed_src(src)
      uri = URI.parse(src)
      return src unless uri.relative?

      "#{URL.url}#{src}"
    end
    private_class_method :parsed_src
  end
end
