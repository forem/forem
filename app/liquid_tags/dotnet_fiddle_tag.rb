require "uri"

class DotnetFiddleTag < LiquidTagBase
  PARTIAL = "liquids/dotnetfiddle".freeze
  LINK_REGEXP = %r{\A(https)://(dotnetfiddle\.net)/(Widget)/[a-zA-Z0-9\-/]*\z}.freeze

  def initialize(_tag_name, link, _parse_context)
    super
    @link = parse_link(link)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        height: 600
      },
    )
  end

  private

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split.first
    raise StandardError, "Invalid DotnetFiddle URL" unless valid_link?(the_link)

    insert_widget(the_link)
  end

  def insert_widget(link)
    uri = URI(link)
    if "Widget".in? uri.path
      link
    else
      # URI.path gives us strings like "/abcde", use substring to get rid of forward slash
      # otherwise join won't work
      URI.join("https://dotnetfiddle.net", "/Widget/", uri.path[1..]).to_s
    end
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    link_no_space.match?(LINK_REGEXP)
  end
end

Liquid::Template.register_tag("dotnetfiddle", DotnetFiddleTag)
