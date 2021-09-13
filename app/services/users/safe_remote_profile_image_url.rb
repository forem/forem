module Users
  module SafeRemoteProfileImageUrl
    # Basic check for nil and blank URLs, alongside likely incomplete URLs, such as just "image.jpg".
    def self.call(url)
      url.gsub!("http://", "https://") if url.match?(%r{https?://})

      url.presence || Users::ProfileImageGenerator.call
    end
  end
end
