module Giphy
  class Image
    def self.valid_url?(source)
      uri = URI.parse(source)

      return false if uri.scheme != "https"
      return false if uri.userinfo || uri.fragment || uri.query
      return false if uri.host != "media.giphy.com" && uri.host != "i.giphy.com"
      return false if uri.port != 443 # I think it has to be this if its https?

      uri.path.ends_with?(".gif")
    end
  end
end
