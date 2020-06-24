module WebMentions
  class WebMentionHandler
    def initialize(canonical_url, article_url = nil)
      @canonical_url = canonical_url
      @article_url = article_url
      @webmention_url = ""
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      accepts_webmention? ? send_webmention : Rails.logger.info("#{@canonical_url} doesn't support Webmentions")
    end

    def accepts_webmention?
      webmention_url.blank? ? false : true
    end

    def webmention_url
      document = Nokogiri::HTML.parse(URI.open(@canonical_url)).at_css("link[rel='webmention']")

      if document
        @webmention_url = if Addressable::URI.parse(document["href"]).relative?
                            Addressable::URI.parse(@canonical_url).origin + document["href"]
                          else
                            document["href"]
                          end
      end
      nil
    rescue StandardError => e
      Rails.logger.error("WebmentionsException: #{e}")
      nil
    end

    private

    def send_webmention
      RestClient.post(@webmention_url, "source": @article_url, "target": @canonical_url)
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("SendWebmentionException: #{e.response}")
    end
  end
end
