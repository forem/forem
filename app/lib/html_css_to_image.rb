module HtmlCssToImage
  AUTH = { username: ApplicationConfig["HCTI_API_USER_ID"],
           password: ApplicationConfig["HCTI_API_KEY"] }.freeze

  CACHE_EXPIRATION = 6.weeks

  def self.url(html:, css: nil, google_fonts: nil)
    image = HTTParty.post("https://hcti.io/v1/image",
                          body: { html: html, css: css, google_fonts: google_fonts },
                          basic_auth: AUTH)

    image["url"] || fallback_image
  end

  def self.fetch_url(html:, css: nil, google_fonts: nil)
    cache_key = "htmlcssimage/#{html}/#{css}/#{google_fonts}"
    cached_url = Rails.cache.read(cache_key)

    return cached_url if cached_url.present?

    image_url = url(html: html, css: css, google_fonts: google_fonts)
    unless image_url == fallback_image
      Rails.cache.write(cache_key, image_url, expires_in: CACHE_EXPIRATION)
    end

    image_url
  end

  def self.fallback_image
    Settings::General.main_social_image.to_s
  end
end
