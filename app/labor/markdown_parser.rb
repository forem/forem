class MarkdownParser
  include ApplicationHelper
  include CloudinaryHelper

  WORDS_READ_PER_MINUTE = 275.0

  def initialize(content)
    @content = content
  end

  def finalize(link_attributes: {})
    options = { hard_wrap: true, filter_html: false, link_attributes: link_attributes }
    renderer = Redcarpet::Render::HTMLRouge.new(options)
    markdown = Redcarpet::Markdown.new(renderer, REDCARPET_CONFIG)
    catch_xss_attempts(@content)
    escaped_content = escape_liquid_tags_in_codeblock(@content)
    html = markdown.render(escaped_content)
    sanitized_content = sanitize_rendered_markdown(html)
    begin
      parsed_liquid = Liquid::Template.parse(sanitized_content)
      html = markdown.render(parsed_liquid.render)
    rescue Liquid::SyntaxError => e
      html = e.message
    end
    html = remove_nested_linebreak_in_list(html)
    html = prefix_all_images(html)
    html = wrap_all_images_in_links(html)
    html = wrap_all_tables(html)
    html = remove_empty_paragraphs(html)
    html = escape_colon_emojis_in_codeblock(html)
    html = unescape_raw_tag_in_codeblocks(html)
    html = wrap_all_figures_with_tags(html)
    wrap_mentions_with_links!(html)
  end

  def calculate_reading_time
    word_count = @content.split(/\W+/).count
    (word_count / WORDS_READ_PER_MINUTE).ceil
  end

  def evaluate_markdown
    return if @content.blank?

    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer, REDCARPET_CONFIG)
    allowed_tags = %w[strong abbr aside em p h1 h2 h3 h4 h5 h6 i u b code pre
                      br ul ol li small sup sub img a span hr blockquote kbd]
    allowed_attributes = %w[href strong em ref rel src title alt class]
    ActionController::Base.helpers.sanitize markdown.render(@content),
                                            tags: allowed_tags,
                                            attributes: allowed_attributes
  end

  def evaluate_limited_markdown
    return if @content.blank?

    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer, REDCARPET_CONFIG)
    allowed_tags = %w[strong i u b em p br code]
    allowed_attributes = %w[href strong em ref rel src title alt class]
    ActionController::Base.helpers.sanitize markdown.render(@content),
                                            tags: allowed_tags,
                                            attributes: allowed_attributes
  end

  def evaluate_inline_limited_markdown
    return if @content.blank?

    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer, REDCARPET_CONFIG)
    allowed_tags = %w[strong i u b em code]
    allowed_attributes = %w[href strong em ref rel src title alt class]
    ActionController::Base.helpers.sanitize markdown.render(@content),
                                            tags: allowed_tags,
                                            attributes: allowed_attributes
  end

  def evaluate_listings_markdown
    return if @content.blank?

    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer, REDCARPET_CONFIG)
    allowed_tags = %w[strong abbr aside em p h4 h5 h6 i u b code pre
                      br ul ol li small sup sub a span hr blockquote kbd]
    allowed_attributes = %w[href strong em ref rel src title alt class]
    ActionController::Base.helpers.sanitize markdown.render(@content),
                                            tags: allowed_tags,
                                            attributes: allowed_attributes
  end

  def tags_used
    return [] if @content.blank?

    cleaned_parsed = escape_liquid_tags_in_codeblock(@content)
    tags = []
    Liquid::Template.parse(cleaned_parsed).root.nodelist.each do |node|
      tags << node.class if node.class.superclass.to_s == LiquidTagBase.to_s
    end
    tags.uniq
  rescue Liquid::SyntaxError
    []
  end

  def prefix_all_images(html, width = 880)
    # wrap with Cloudinary or allow if from giphy or githubusercontent.com
    doc = Nokogiri::HTML.fragment(html)
    doc.css("img").each do |img|
      src = img.attr("src")
      next unless src
      # allow image to render as-is
      next if allowed_image_host?(src)

      img["loading"] = "lazy"
      img["src"] = if Giphy::Image.valid_url?(src)
                     src.gsub("https://media.", "https://i.")
                   else
                     img_of_size(src, width)
                   end
    end
    doc.to_html
  end

  private

  def escape_colon_emojis_in_codeblock(html)
    html_doc = Nokogiri::HTML.fragment(html)

    html_doc.children.each do |el|
      next if el.name == "code"

      if el.search("code").empty?
        el.swap(EmojiConverter.call(el.to_html))
      else
        el.children = escape_colon_emojis_in_codeblock(el.children.to_html)
      end
    end
    html_doc.to_html
  end

  def catch_xss_attempts(markdown)
    bad_xss = ['src="data', "src='data", "src='&", 'src="&', "data:text/html"]
    bad_xss.each do |xss_attempt|
      raise ArgumentError, "Invalid markdown detected" if markdown.include?(xss_attempt)
    end
  end

  def allowed_image_host?(src)
    # GitHub camo image won't parse but should be safe to host direct
    src.start_with?("https://camo.githubusercontent.com/")
  end

  def remove_nested_linebreak_in_list(html)
    html_doc = Nokogiri::HTML(html)
    html_doc.xpath("//*[self::ul or self::ol or self::li]/br").each(&:remove)
    html_doc.to_html
  end

  def escape_liquid_tags_in_codeblock(content)
    # Escape codeblocks, code spans, and inline code
    content.gsub(/[[:space:]]*`{3}.*?`{3}|`{2}.+?`{2}|`{1}.+?`{1}/m) do |codeblock|
      codeblock.gsub!("{% endraw %}", "{----% endraw %----}")
      codeblock.gsub!("{% raw %}", "{----% raw %----}")
      if codeblock.match?(/[[:space:]]*`{3}/)
        "\n{% raw %}\n" + codeblock + "\n{% endraw %}\n"
      else
        "{% raw %}" + codeblock + "{% endraw %}"
      end
    end
  end

  def possibly_raw_tag_syntax?(array)
    array.any? { |string| ["{", "}", "raw", "endraw", "----"].include?(string) }
  end

  def unescape_raw_tag_in_codeblocks(html)
    html.gsub!("{----% raw %----}", "{% raw %}")
    html.gsub!("{----% endraw %----}", "{% endraw %}")
    html_doc = Nokogiri::HTML(html)
    html_doc.xpath("//body/div/pre/code").each do |codeblock|
      next unless codeblock.content.include?("{----% raw %----}") || codeblock.content.include?("{----% endraw %----}")

      children_content = codeblock.children.map(&:content)
      indices = children_content.size.times.select do |i|
        possibly_raw_tag_syntax?(children_content[i..i + 2])
      end
      indices.each do |i|
        codeblock.children[i].content = codeblock.children[i].content.delete("----")
      end
    end
    if html_doc.at_css("body")
      html_doc.at_css("body").inner_html
    else
      html_doc.to_html
    end
  end

  def wrap_all_figures_with_tags(html)
    html_doc = Nokogiri::HTML(html)

    html_doc.xpath("//figcaption").each do |caption|
      next if caption.parent.name == "figure"
      next unless caption.previous_element

      fig = html_doc.create_element "figure"
      prev = caption.previous_element
      prev.replace(fig) << prev << caption
    end
    if html_doc.at_css("body")
      html_doc.at_css("body").inner_html
    else
      html_doc.to_html
    end
  end

  def wrap_mentions_with_links!(html)
    html_doc = Nokogiri::HTML(html)

    # looks for nodes that isn't <code>, <a>, and contains "@"
    targets = html_doc.xpath('//html/body/*[not (self::code) and not(self::a) and contains(., "@")]').to_a

    # A Queue system to look for and replace possible usernames
    until targets.empty?
      node = targets.shift

      # only focus on portion of text with "@"
      node.xpath("text()[contains(.,'@')]").each do |el|
        el.replace(el.text.gsub(/\B@[a-z0-9_-]+/i) { |text| user_link_if_exists(text) })
      end

      # enqueue children that has @ in it's text
      children = node.xpath('*[not(self::code) and not(self::a) and contains(., "@")]').to_a
      targets.concat(children)
    end

    if html_doc.at_css("body")
      html_doc.at_css("body").inner_html
    else
      html_doc.to_html
    end
  end

  def user_link_if_exists(mention)
    username = mention.delete("@").downcase
    if User.find_by(username: username)
      <<~HTML
        <a class='comment-mentioned-user' href='#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}/#{username}'>@#{username}</a>
      HTML
    else
      mention
    end
  end

  def img_of_size(source, width = 880)
    quality = if source && (source.include? ".gif")
                66
              else
                "auto"
              end
    cl_image_path(source,
                  type: "fetch",
                  width: width,
                  crop: "limit",
                  quality: quality,
                  flags: "progressive",
                  fetch_format: "auto",
                  sign_url: true).gsub(",", "%2C")
  end

  def wrap_all_images_in_links(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.search("p img").each do |image|
      image.swap("<a href='#{image.attr('src')}' class='article-body-image-wrapper'>#{image}</a>") unless image.parent.name == "a"
    end
    doc.to_html
  end

  def remove_empty_paragraphs(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.css("p").select { |paragraph| all_children_are_blank?(paragraph) }.each(&:remove)
    doc.to_html
  end

  def wrap_all_tables(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.search("table").each { |table| table.swap("<div class='table-wrapper-paragraph'>#{table}</div>") }
    doc.to_html
  end

  def all_children_are_blank?(node)
    node.children.all? { |child| blank?(child) }
  end

  def blank?(node)
    (node.text? && node.content.strip == "") || (node.element? && node.name == "br")
  end
end
