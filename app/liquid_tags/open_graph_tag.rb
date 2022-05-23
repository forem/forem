# OpenGraphTag is NOT registered in the Registry; rather, it is a fallback
class OpenGraphTag < LiquidTagBase
  PARTIAL = "liquids/open_graph".freeze
  attr_accessor :page

  def initialize(_tag_name, url, _parse_context)
    super

    @url = url
    @page = OpenGraph.new url
    @url_domain = URI.parse(url).host.delete_prefix("www.")
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        page: @page,
        url: @url,
        url_domain: @url_domain
      },
    )
  end
end
