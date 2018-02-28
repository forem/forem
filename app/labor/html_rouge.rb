require "rouge/plugins/redcarpet"

class HtmlRouge < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet

  def link(link, _title, content)
    # Probably not the best fix but it does it's job of preventing
    # a nested links.
    return nil if /<a\s.+\/a>/ =~ content
    %(<a href="#{link}">#{content}</a>)
  end
end
