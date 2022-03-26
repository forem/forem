class OpenGraphTag < LiquidTagBase
  PARTIAL = "liquids/open_graph".freeze
  REGISTRY_REGEXP = /.*/
  attr_accessor :page

  def initialize(_tag_name, url, _parse_context)
    super

    @page = OpenGraph.new url
  end

  def render(_context)
    ApplicationController.render(partial: PARTIAL, locals: { page: page })
  end
end

UnifiedEmbed.register(OpenGraphTag, regexp: OpenGraphTag::REGISTRY_REGEXP)
