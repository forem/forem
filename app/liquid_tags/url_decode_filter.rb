module UrlDecodeFilter
  def url_decode(input)
    input
  end
end

Liquid::Template.register_filter(UrlDecodeFilter)
