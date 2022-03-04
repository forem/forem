class KotlinTag < LiquidTagBase
  PARTIAL = "liquids/kotlin".freeze
  REGISTRY_REGEXP = %r{https://pl\.kotl\.in/(?<id>[\w-]+)(?:\?)?(?<params>[\w=&]+)?}
  PARAM_REGEXP = /\A(theme=darcula)|(readOnly=true)|(from=\d)|(to=\d)\Z/

  def initialize(_tag_name, link, _parse_context)
    super
    stripped_link = strip_tags(link)
    unescaped_link = CGI.unescape_html(stripped_link)
    @url = parsed_link(unescaped_link)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @url
      },
    )
  end

  def parsed_link(link)
    match = pattern_match_for(link, [REGISTRY_REGEXP])
    raise StandardError, I18n.t("liquid_tags.kotlin_tag.invalid_kotlin_playground") unless match

    return link unless match[:params]

    build_link_with_params(match[:id], match[:params])
  end

  private

  def build_link_with_params(id, params)
    params = params.split("&")
    vetted_params = params.filter_map { |param| param if valid_param(param) }.join("&")

    "https://pl.kotl.in/#{id}?#{vetted_params}"
  end

  def valid_param(param)
    (param =~ PARAM_REGEXP)&.zero?
  end
end

Liquid::Template.register_tag("kotlin", KotlinTag)

UnifiedEmbed.register(KotlinTag, regexp: KotlinTag::REGISTRY_REGEXP)
