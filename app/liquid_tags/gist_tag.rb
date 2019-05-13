class GistTag < LiquidTagBase
  def initialize(tag_name, link, tokens)
    super
    @uri = build_uri(link)
  end

  def render(_context)
    html = <<~HTML
      <div class="ltag_gist-liquid-tag">
          <script id="gist-ltag" src="#{@uri}"></script>
      </div>
    HTML
    finalize_html(html)
  end

  def self.special_script
    <<~JAVASCRIPT
      if (postscribe) {
        var els = document.getElementsByClassName("ltag_gist-liquid-tag")
        for (i = 0; i < els.length; i++) {
            postscribe(els[i], els[i].firstElementChild.outerHTML);
        }
      }
    JAVASCRIPT
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

    raise StandardError, "Invalid Options"
  end

  def valid_link?(link)
    (link =~ /\Ahttps\:\/\/gist\.github\.com\/([a-zA-Z0-9](-?[a-zA-Z0-9]){0,38})\/([a-zA-Z0-9]){1,32}\Z/)&.
      zero?
  end

  def valid_option?(option)
    (option =~ /\Afile\=[^\\]*\.(\w+)\Z/)&.zero?
  end
end

Liquid::Template.register_tag("gist", GistTag)
