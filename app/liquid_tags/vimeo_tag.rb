class VimeoTag < LiquidTagBase
  PARTIAL = "liquids/vimeo".freeze
  REGISTRY_REGEXP = %r{https?://(player\.|www\.)?vimeo\.com/(video/|embed/|watch)?(ondemand/\w+/)?(\d*)}

  def initialize(_tag_name, token, _parse_context)
    super
    url = ActionController::Base.helpers.strip_tags(token).strip
    @id     = get_id(url)
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

  def get_id(url)
    url.to_s.scan(/\d+/).first
  end
end

Liquid::Template.register_tag("vimeo", VimeoTag)

# NOTE: this does not process Vimeo Showcase IDs; add to documentation
UnifiedEmbed.register(VimeoTag, regexp: VimeoTag::REGISTRY_REGEXP)

# https://player.vimeo.com/video/652446985?h=a68f6ed1f5
# https://vimeo.com/ondemand/withchude/647355334
# https://vimeo.com/636725488
