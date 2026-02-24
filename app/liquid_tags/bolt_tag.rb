class BoltTag < LiquidTagBase
  PARTIAL = "liquids/bolt".freeze
  BOLT_HOST_REGEXP = %r{\Ahttps://[\w-]+\.bolt\.host/?\z}
  BOLT_NEW_REGEXP = %r{\Ahttps://bolt\.new/~/[\w-]+/?\z}
  REGISTRY_REGEXP = %r{https://(?:[\w-]+\.bolt\.host|bolt\.new/~/[\w-]+)}

  def initialize(_tag_name, input, _parse_context)
    super
    @url = parse_input(strip_tags(input))
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { url: @url },
    )
  end

  private

  def parse_input(input)
    stripped = input.strip
    if stripped.match?(BOLT_HOST_REGEXP)
      stripped.chomp("/")
    elsif stripped.match?(BOLT_NEW_REGEXP)
      stripped.chomp("/")
    else
      raise StandardError, I18n.t("liquid_tags.bolt_tag.invalid_url", default: "Invalid Bolt URL")
    end
  end
end

Liquid::Template.register_tag("bolt", BoltTag)
UnifiedEmbed.register(BoltTag, regexp: BoltTag::REGISTRY_REGEXP)
