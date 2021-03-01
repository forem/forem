module Users
  module SafeRemoteProfileImageUrl
    # Basic check for nil and blank URLs, alongside likely incomplete URLs, such as just "image.jpg".
    def self.call(url)
      return url if url.to_s.start_with?("https")

      Users::ProfileImageGenerator.call
    end
  end
end
