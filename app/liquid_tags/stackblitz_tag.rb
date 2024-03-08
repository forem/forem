class StackblitzTag < LiquidTagBase
  PARTIAL = "liquids/stackblitz".freeze
  REGISTRY_REGEXP = %r{https://stackblitz\.com/edit/(?<id>[\w-]{,60})(?<params>\?.*)?}
  ID_REGEXP = /\A(?<id>[\w-]{,60})\Z/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, ID_REGEXP].freeze
  # rubocop:disable Layout/LineLength
  PARAM_REGEXP = /\A(view=(preview|editor|both))|(file=(.*))|(embed=1)|(hideExplorer=1)|(hideNavigation=1)|(theme=(default|light|dark))|(ctl=1)|(devtoolsheight=\d)|(hidedevtools=1)|(initialpath=(.*))|(showSidebar=1)|(terminalHeight=\d)|(startScript=(.*))\Z/
  # rubocop:enable Layout/LineLength

  def initialize(_tag_name, input, _parse_context)
    super

    stripped_input  = strip_tags(input)
    unescaped_input = CGI.unescape_html(stripped_input)
    @id, @params = parsed_input(unescaped_input)
    @height = 500
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        params: @params,
        height: @height
      },
    )
  end

  private

  def parsed_input(input)
    id, *params = input.split
    match = pattern_match_for(id, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.stackblitz_tag.invalid_stackblitz_id") unless match

    return [match[:id], nil] unless url_params(match) || params

    build_link_with_params(match[:id], (url_params(match) || params))
  end

  def url_params(match)
    return unless match.names.include?("params")

    match[:params].delete("?")
  end

  def build_link_with_params(id, params)
    params = params.split("&") if params.is_a?(String)
    vetted_params = params.select { |param| valid_param(param) }.join("&")

    [id, vetted_params]
  end

  def valid_param(param)
    (param =~ PARAM_REGEXP)&.zero?
  end
end

Liquid::Template.register_tag("stackblitz", StackblitzTag)

UnifiedEmbed.register(StackblitzTag, regexp: StackblitzTag::REGISTRY_REGEXP)
