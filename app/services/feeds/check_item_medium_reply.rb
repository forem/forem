# Checks if a Feedjira item represents a user's comment on a Medium post as
# unfortunately they include those as items in their feeds
module Feeds
  class CheckItemMediumReply
    MEDIUM_DOMAIN = "medium.com".freeze

    def self.call(item)
      new(item).call
    end

    def initialize(item)
      @item = item
    end

    def call
      get_host_without_www(item.url.strip) == MEDIUM_DOMAIN &&
        !item[:categories] &&
        content_is_not_the_title?(item)
    end

    private

    attr_reader :item

    def get_host_without_www(url)
      ForemNative.host_without_www(url) || legacy_get_host_without_www(url)
    end

    # Handles the URLs ForemNative declines (non-ASCII text, userinfo, IP literals, ...).
    def legacy_get_host_without_www(url)
      url = "http://#{url}" if Addressable::URI.parse(url).scheme.nil?
      host = Addressable::URI.parse(url).host.downcase
      host.start_with?("www.") ? host[4..] : host
    end

    def content_is_not_the_title?(item)
      result = ForemNative.content_includes_title(item.content, item.title)
      result.nil? ? legacy_content_is_not_the_title?(item) : result
    end

    # Handles the contents and titles ForemNative declines (nil, non-UTF-8, invalid UTF-8).
    def legacy_content_is_not_the_title?(item)
      # [[:space:]] removes all whitespace, including unicode ones.
      content = item.content.gsub(/[[:space:]]/, " ")
      title = item.title.delete("…")
      content.include?(title)
    end
  end
end
