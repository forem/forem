class StackeryTag < LiquidTagBase
  PARTIAL = "liquids/stackery".freeze
  REGISTRY_REGEXP = %r{https://app\.stackery\.io/editor/design(?<params>\?.*)?}
  PARAM_REGEXP = /\A(owner=[\w-]+)|(repo=[\w-]+)|(file=.*)|(ref=.*)\Z/

  def initialize(_tag_name, input, _parse_context)
    super

    stripped_input  = strip_tags(input)
    unescaped_input = CGI.unescape_html(stripped_input)
    @params = parsed_input(unescaped_input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        params: @params
      },
    )
  end

  private

  def parsed_input(input)
    if input.split.length > 1
      params = input.split
      owner = params.first
      repo = params.second
      ref = params.third || "master"

      raise StandardError, I18n.t("liquid_tags.stackery_tag.missing_argument") unless owner && repo

      "owner=#{owner}&repo=#{repo}&ref=#{ref}"
    else
      match = pattern_match_for(input, [REGISTRY_REGEXP])
      raise StandardError, I18n.t("liquid_tags.stackery_tag.missing_argument") unless match

      extract_params(match[:params])
    end
  end

  def extract_params(params)
    params = params.delete("?").split("&")
    params.select { |param| valid_param(param) }.join("&")
  end

  def valid_param(param)
    (param =~ PARAM_REGEXP)&.zero?
  end
end

Liquid::Template.register_tag("stackery", StackeryTag)

UnifiedEmbed.register(StackeryTag, regexp: StackeryTag::REGISTRY_REGEXP)
