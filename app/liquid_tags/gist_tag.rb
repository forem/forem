class GistTag < LiquidTagBase
  PARTIAL = "liquids/gist".freeze
  VALID_LINK_REGEXP =
    %r{\Ahttps://gist\.github\.com/([a-zA-Z0-9](-?[a-zA-Z0-9]){0,38})/([a-zA-Z0-9]){1,32}(/[a-zA-Z0-9]+)?\Z}

  def initialize(_tag_name, link, _parse_context)
    super

    raise StandardError, "Invalid Gist link: You must provide a Gist link" if link.blank?

    @uri = build_uri(link)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        uri: @uri
      },
    )
  end

  private

  def build_uri(link)
    link = ActionController::Base.helpers.strip_tags(link)
    link, option = link.split(" ", 2)
    link = parse_link(link)

    uri = "#{link}.js"
    uri += build_options(option) unless option&.empty?

    uri
  end

  def parse_link(link)
    input_no_space = link.delete(" ").gsub(".js", "")
    if valid_link?(input_no_space)
      input_no_space
    else
      raise StandardError,
            "Invalid Gist link: #{link} Links must follow this format: https://gist.github.com/username/gist_id"
    end
  end

  def build_options(option)
    option_no_space = option.strip
    return "?#{option_no_space}" if valid_option?(option_no_space)

    raise StandardError, "Invalid Filename"
  end

  def valid_link?(link)
    (link =~ VALID_LINK_REGEXP)&.zero?
  end

  def valid_option?(option)
    (option =~ /\Afile=[^\\]*(\.(\w+))?\Z/)&.zero?
  end
end

Liquid::Template.register_tag("gist", GistTag)
