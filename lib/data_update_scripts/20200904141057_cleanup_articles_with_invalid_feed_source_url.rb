module DataUpdateScripts
  class CleanupArticlesWithInvalidFeedSourceUrl
    def run
      # We need this to intercept those strings that would be valid URLs if the scheme were added,
      # so I slightly modified the Ruby URL regexp from https://urlregex.com/ to avoid checking for the scheme
      almost_url_regexp = %r{\A(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:/[^\s]*)?\z}i # rubocop:disable Layout/LineLength

      Article.where.not(feed_source_url: nil).where("feed_source_url NOT ILIKE ?", "http%").find_each do |article|
        fixed_feed_source_url = article.canonical_url.presence ||
          (almost_url_regexp.match?(article.feed_source_url) ? "https://#{article.feed_source_url}" : nil)

        article.update_columns(feed_source_url: fixed_feed_source_url)
      end
    end
  end
end
