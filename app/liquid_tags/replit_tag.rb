class ReplitTag < LiquidTagBase
  PARTIAL = "liquids/replit".freeze
  REGISTRY_REGEXP = %r{https?://replit.com/(?<address>@\w{2,15}/[a-zA-Z0-9\-]{0,60})(?:#[\w.]+)?}
  VALID_ADDRESS = %r{(?<address>@\w{2,15}/[a-zA-Z0-9\-]{0,60})(?:#[\w.]+)?}
  REGEXP_OPTIONS = [REGISTRY_REGEXP, VALID_ADDRESS].freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @address = parse_input(strip_tags(input))
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        address: @address
      },
    )
  end

  private

  def parse_input(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, "Invalid Replit URL or @user/slug" unless match

    match[:address]
  end
end

Liquid::Template.register_tag("replit", ReplitTag)

UnifiedEmbed.register(ReplitTag, regexp: ReplitTag::REGISTRY_REGEXP)
