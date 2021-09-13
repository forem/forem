module Users
  module SafeRemoteProfileImageUrl
    # Basic check for nil and blank URLs, alongside likely incomplete URLs, such as just "image.jpg".
    def self.call(url)
      if url.match?(%r{https?://})
        url[0..6].gsub("http://", "https://") + url[7..]
      else
        Users::ProfileImageGenerator.call
      end
    end
  end
end
