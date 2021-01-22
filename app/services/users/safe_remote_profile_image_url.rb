module Users
  module SafeRemoteProfileImageUrl
    # Basic check for nil and blank URLs, alongside likely incomplete URLs, such as just "image.jpg".
    def self.call(url)
      return Users::ProfileImageGenerator.call unless url.to_s.start_with?("https")

      url
    end
  end
end
