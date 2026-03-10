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
end
