# OpenGraphTag is NOT registered in the Registry; rather, it is a fallback
class OpenGraphTag < LiquidTagBase
  PARTIAL = "liquids/open_graph".freeze
  attr_accessor :page

  def initialize(_tag_name, url, _parse_context)
    super

    @page = OpenGraph.new url
    @plain_url = url
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        page: page,
        plain_url: @plain_url
      },
    )
  end
end
