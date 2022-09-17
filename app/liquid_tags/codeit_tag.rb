class CodeitTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @url = parse_url(url)
  end

  def render(_context)
    '<iframe src="' + @url + '"
      scrolling="no" frameborder="no" allowtransparency="true" allowfullscreen="true" loading="lazy" style="width: 100%;" height="600"
    </iframe>'
  end

  private

  def parse_url(url)
    if (url.match(/^https:\/\/cde.run\//) || url.match(/^https:\/\/dev.cde.run\//))
      url = url
    else
      url = 'https://cde.run/' + url
    return url
    end
  end

  end
end

Liquid::Template.register_tag("codeit", CodeitTag)
Liquid::Template.register_tag("cd", CodeitTag)
