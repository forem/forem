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
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    raise_error unless valid_link?(stripped_link)
    stripped_link.tr(" ", "")
  end

  def valid_link?(link)
    link.include?("soundcloud.com")
  end

  def raise_error
    raise StandardError, "Invalid Soundcloud URL"
  end
end

Liquid::Template.register_tag("soundcloud", SoundcloudTag)
