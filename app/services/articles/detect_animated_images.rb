module Articles
  module DetectAnimatedImages
    IMAGES_IN_LIQUID_TAGS_SELECTORS = [
      ".liquid-comment img", # CommentTag
      ".ltag-github-readme-tag img", # GithubReadmeTag
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

      images.each do |img|
        src = img.attr("src")
        next unless src

        animated = FastImage.animated?(src)
        img["data-animated"] = true if animated
      end

      article.save
    end
  end
end
