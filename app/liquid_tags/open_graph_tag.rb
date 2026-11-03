# OpenGraphTag is NOT registered in the Registry; rather, it is a fallback
class OpenGraphTag < LiquidTagBase
  PARTIAL = "liquids/open_graph".freeze
  attr_accessor :page

  def initialize(_tag_name, url, _parse_context)
    super

    uri = URI.parse(url.to_s.split.first.to_s)
    unless %w[http https].include?(uri.scheme) && uri.host.present?
      raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url")
    end

    @url = url
    @page = OpenGraph.new url
    @url_domain = uri.host.delete_prefix("www.")
  rescue URI::InvalidURIError
    raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url")
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
