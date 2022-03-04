module Users
  module SafeRemoteProfileImageUrl
    # Basic check for nil and blank URLs, alongside likely incomplete URLs, such as just "image.jpg".
    def self.call(url)
      if url&.start_with?("http")
        url.sub!("http://", "https://")
        url
      else
        Users::ProfileImageGenerator.call
      end
    end
  end
end
