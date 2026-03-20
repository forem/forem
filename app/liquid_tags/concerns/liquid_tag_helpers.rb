module LiquidTagHelpers
  extend ActiveSupport::Concern

  OPTION_REGEXP = /(\w+)=(?:"([^"]+)"|(\S+))/

  def fully_unescape_html(str)
    prev = nil
    while str != prev
      prev = str
      str = CGI.unescape_html(str)
    end
    str
  end

  def parse_options(markup)
    cleaned = respond_to?(:strip_tags, true) ? strip_tags(markup) : markup
    options = {}
    cleaned.scan(OPTION_REGEXP) do |key, quoted_val, plain_val|
      options[key] = (quoted_val || plain_val).strip
    end
    options
  end

  def validate_url!(url, option_name = "url")
    return if url.blank?

    uri = URI.parse(url)
    raise StandardError, I18n.t("liquid_tags.invalid_url_scheme", option: option_name) unless %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    raise StandardError, I18n.t("liquid_tags.invalid_url_scheme", option: option_name)
  end
end
