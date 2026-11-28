class VimeoTag < LiquidTagBase
  PARTIAL = "liquids/vimeo".freeze
  # rubocop:disable Layout/LineLength
  REGISTRY_REGEXP = %r{(?:https?://)?(?:player\.|www\.)?vimeo\.com/(?:video/|embed/|watch)?(?:ondemand/\w+/)?(?<video_id>\d+)(?:/(?<path_hash>\h{8,12})(?![\w-]))?(?:\?(?:[^\s#]*&)?h=(?<query_hash>\h{8,12})(?![\w-]))?}
  # rubocop:enable Layout/LineLength
  ID_REGEXP = /\A\d+\z/

  def initialize(_tag_name, token, _parse_context)
    super
    input   = strip_tags(token)
    @id, @privacy_hash = get_id_and_hash(CGI.unescape_html(input))
    @width  = 710
    @height = 399
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
        privacy_hash: @privacy_hash,
        width: @width,
        height: @height
      },
    )
  end

  private

  # Unlisted videos only play when the player URL carries the privacy hash that
  # Vimeo puts in the share link (vimeo.com/<id>/<hash>) or in the player URL
  # as ?h=<hash>, so keep it alongside the id.
  def get_id_and_hash(input)
    match = input.match(REGISTRY_REGEXP)
    id = match ? match[:video_id] : input
    raise StandardError, I18n.t("liquid_tags.vimeo_tag.invalid_vimeo_id") unless id.match?(ID_REGEXP)

    [id, match && (match[:path_hash] || match[:query_hash])]
  end
end

Liquid::Template.register_tag("vimeo", VimeoTag)

# NOTE: this does not process Vimeo Showcase IDs; add to documentation
UnifiedEmbed.register(VimeoTag, regexp: VimeoTag::REGISTRY_REGEXP)
