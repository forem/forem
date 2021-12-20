class VimeoTag < LiquidTagBase
  PARTIAL = "liquids/vimeo".freeze
  # rubocop:disable Layout/LineLength
  REGISTRY_REGEXP = %r{(?:https?://)?(?:player\.|www\.)?vimeo\.com/(?:video/|embed/|watch)?(?:ondemand/\w+/)?(?<video_id>\d*)}
  # rubocop:enable Layout/LineLength

  def initialize(_tag_name, token, _parse_context)
    super
    input   = strip_tags(token)
    @id     = get_id(input)
    @width  = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        width: @width,
        height: @height
      },
    )
  end

  private

  def get_id(input)
    match = input.match(REGISTRY_REGEXP)
    match ? match[:video_id] : input
  end
end

Liquid::Template.register_tag("vimeo", VimeoTag)

# NOTE: this does not process Vimeo Showcase IDs; add to documentation
UnifiedEmbed.register(VimeoTag, regexp: VimeoTag::REGISTRY_REGEXP)
