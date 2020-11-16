class SoundcloudTag < LiquidTagBase
  PARTIAL = "liquids/soundcloud".freeze

  def initialize(_tag_name, link, _parse_context)
    super
    @link = parse_link(link)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        height: 166
      },
    )
  end

  private

  def parse_link(link)
    stripped_link = sanitize_link(link)
    raise_error unless valid_link?(stripped_link)
    stripped_link
  end

  def sanitize_link(link)
    link = ActionController::Base.helpers.strip_tags(link)
    link = ActionController::Base.helpers.sanitize(link)
    link.tr(" ", "")
  end

  def valid_link?(link)
    (link =~ %r{\Ahttps://soundcloud\.com/([a-zA-Z0-9_\-]){3,25}/(sets/)?([a-zA-Z0-9_\-]){3,255}\Z})
      &.zero?
  end

  def raise_error
    raise StandardError, "Invalid Soundcloud URL - try taking off any URL params: '?something=value'"
  end
end

Liquid::Template.register_tag("soundcloud", SoundcloudTag)
