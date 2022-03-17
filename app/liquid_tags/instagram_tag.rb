class InstagramTag < LiquidTagBase
  PARTIAL = "liquids/instagram".freeze
  # rubocop:disable Layout/LineLength
  REGISTRY_REGEXP = %r{(?:https?://)?(?:www\.)?instagram\.com/(?:(?:(?:p/)(?<post_id>[\w-]{11}))|(?<handle>[\w.]{,30}))/?(?:\?.*)?}
  # rubocop:enable Layout/LineLength
  VALID_ID_REGEXP = /\A(?<post_id>[\w-]{11})\Z/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, VALID_ID_REGEXP].freeze

  def initialize(_tag_name, id, _parse_context)
    super
    input   = CGI.unescape_html(strip_tags(id))
    @path   = parse_id_or_url(input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        path: @path
      },
    )
  end

  private

  def parse_id_or_url(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.instagram_tag.invalid_instagram_id") unless match

    if match_has_named_capture_group?(match, "handle") && match[:handle].present?
      return "#{match[:handle]}/embed/"
    end

    "p/#{match[:post_id]}/embed/captioned/"
  end
end

Liquid::Template.register_tag("instagram", InstagramTag)

UnifiedEmbed.register(InstagramTag, regexp: InstagramTag::REGISTRY_REGEXP)
