module WebMentions
  class WebMentionHandler
    def initialize(canonical_url:, article_url: nil, webmention_url: nil)
      @canonical_url = canonical_url
      @article_url = article_url
      @webmention_url = webmention_url
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      return if webmention_url.blank?

      send_webmention
    end

    def webmention_url
      document = Nokogiri::HTML.parse(HTTParty.get(@canonical_url)).at_css("link[rel='webmention']")

      if document
        @webmention_url = if Addressable::URI.parse(document["href"]).relative?
                            Addressable::URI.parse(@canonical_url).origin + document["href"]
                          else
                            document["href"]
                          end
      end
    rescue StandardError => e
      Rails.logger.error("WebmentionsException: #{e}")
      nil
    end

    private

    def send_webmention
      HTTParty.post(@webmention_url, "source": @article_url, "target": @canonical_url)
    rescue HTTParty::Error => e
      Rails.logger.error("SendWebmentionException: #{e.response}")
    end
  end
end
