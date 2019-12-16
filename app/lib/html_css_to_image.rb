module HtmlCssToImage
  AUTH = { username: ApplicationConfig["HCTI_API_USER_ID"],
           password: ApplicationConfig["HCTI_API_KEY"] }.freeze

  FALLBACK_IMAGE = "https://thepracticaldev.s3.amazonaws.com/i/g355ol6qsrg0j2mhngz9.png".freeze

  def self.url(html:, css: nil, google_fonts: nil)
    image = HTTParty.post("https://hcti.io/v1/image",
                          body: { html: html, css: css, google_fonts: google_fonts },
                          basic_auth: AUTH)

    image["url"] || FALLBACK_IMAGE
  end

  def self.fetch_url(html:, css: nil, google_fonts: nil)
    cache_key = "htmlcssimage/#{html}/#{css}/#{google_fonts}"
    cached_url = Rails.cache.read(cache_key)

    return cached_url if cached_url.present?

    image_url = url(html: html, css: css, google_fonts: google_fonts)

    Rails.cache.write(cache_key, image_url) unless image_url == FALLBACK_IMAGE

    image_url
  end
end
