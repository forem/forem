class SoundcloudTag < LiquidTagBase
  def initialize(tag_name, link, tokens)
    super
    @link = parse_link(link)
    @height = 166
  end

  def render(_context)
    # src = build_src
    html = <<-HTML
      <iframe
		width="100%"
		height="#{@height}"
		scrolling="no"
		frameborder="no"
		allow="autoplay"
		src="https://w.soundcloud.com/player/?url=#{@link}&auto_play=false&color=%23000000&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true">
	</iframe>
    HTML
    finalize_html(html)
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
    (link =~ /\Ahttps:\/\/soundcloud\.com\/([a-zA-Z0-9\_\-]){3,25}\/(sets\/)?([a-zA-Z0-9\_\-]){3,255}\Z/)&.
      zero?
  end

  def raise_error
    raise StandardError, "Invalid Soundcloud URL - try taking off any URL params: '?something=value'"
  end
end

Liquid::Template.register_tag("soundcloud", SoundcloudTag)
