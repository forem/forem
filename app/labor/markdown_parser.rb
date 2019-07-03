class MarkdownParser
  include ApplicationHelper
  include CloudinaryHelper

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
    rescue StandardError => e
      raise StandardError, e.message
    end
    html = markdown.render(parsed_liquid.render)
    html = remove_nested_linebreak_in_list(html)
    html = prefix_all_images(html)
    html = wrap_all_images_in_links(html)
    html = wrap_all_tables(html)
    html = remove_empty_paragraphs(html)
    html = escape_colon_emojis_in_codeblock(html)
    wrap_mentions_with_links!(html)
  end

  def calculate_reading_time
    word_count = @content.split(/\W+/).count
    (word_count / 275.0).ceil
  end

  def evaluate_markdown
    return if @content.blank?

    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer, REDCARPET_CONFIG)
    allowed_tags = %w[strong abbr aside em p h1 h2 h3 h4 h5 h6 i u b code pre
                      br ul ol li small sup sub img a span hr blockquote kbd]
    allowed_attributes = %w[href strong em ref rel src title alt class]
    ActionController::Base.helpers.sanitize markdown.render(@content).html_safe,
                                            tags: allowed_tags,
                                            attributes: allowed_attributes
  end

  def evaluate_limited_markdown
    return if @content.blank?

    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer, REDCARPET_CONFIG)
    allowed_tags = %w[strong i u b em p br code]
    allowed_attributes = %w[href strong em ref rel src title alt class]
    ActionController::Base.helpers.sanitize markdown.render(@content).html_safe,
                                            tags: allowed_tags,
                                            attributes: allowed_attributes
  end

  def evaluate_inline_limited_markdown
    return if @content.blank?

    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer, REDCARPET_CONFIG)
    allowed_tags = %w[strong i u b em code]
    allowed_attributes = %w[href strong em ref rel src title alt class]
    ActionController::Base.helpers.sanitize markdown.render(@content).html_safe,
                                            tags: allowed_tags,
                                            attributes: allowed_attributes
  end

  def evaluate_listings_markdown
    return if @content.blank?

    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer, REDCARPET_CONFIG)
    allowed_tags = %w[strong abbr aside em p h1 h2 h3 h4 h5 h6 i u b code pre
                      br ul ol li small sup sub a span hr blockquote kbd]
    allowed_attributes = %w[href strong em ref rel src title alt class]
    ActionController::Base.helpers.sanitize markdown.render(@content).html_safe,
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
      img["src"] = if giphy_img?(src)
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

  def giphy_img?(source)
    uri = URI.parse(source)
    return false if uri.scheme != "https"
    return false if uri.userinfo || uri.fragment || uri.query
    return false if uri.host != "media.giphy.com" && uri.host != "i.giphy.com"
    return false if uri.port != 443 # I think it has to be this if its https?

    uri.path.ends_with?(".gif")
  end

  def remove_nested_linebreak_in_list(html)
    html_doc = Nokogiri::HTML(html)
    html_doc.xpath("//*[self::ul or self::ol or self::li]/br").each(&:remove)
    html_doc.to_html
  end

  def escape_liquid_tags_in_codeblock(content)
    # Escape codeblocks, code spans, and inline code
    content.gsub(/`{3}.*?`{3}|`{2}.+?`{2}|`{1}.+?`{1}/m) do |codeblock|
      if codeblock[0..2] == "```"
        "\n{% raw %}\n" + codeblock + "\n{% endraw %}\n"
      else
        "{% raw %}" + codeblock + "{% endraw %}"
      end
      # Below is the old implementation that replaces all liquid tag.
      # codeblock.gsub(/{%.{1,}[^}]{2}%}/) do |liquid_tag|
      #   liquid_tag.gsub(/{%/, '{{ "{%').gsub(/%}/, '" }}%}')
      # end
    end
  end

  def wrap_mentions_with_links!(html)
    html_doc = Nokogiri::HTML(html)
    html_doc.xpath("//body/*[not (@class='highlight')]").each do |el|
      el.children.each do |child|
        if child.text?
          new_child = child.text.gsub(/\B@[a-z0-9_-]+/i) do |s|
            user_link_if_exists(s)
          end
          child.replace(new_child) if new_child != child.text
        end
      end
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
    doc.search("p img").each do |i|
      i.swap("<a href='#{i.attr('src')}' class='article-body-image-wrapper'>#{i}</a>") unless i.parent.name == "a"
    end
    doc.to_html
  end

  def remove_empty_paragraphs(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.css("p").select { |p| all_children_are_blank?(p) }.each(&:remove)
    doc.to_html
  end

  def wrap_all_tables(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.search("table").each { |i| i.swap("<div class='table-wrapper-paragraph'>#{i}</div>") }
    doc.to_html
  end

  def all_children_are_blank?(node)
    node.children.all? { |child| blank?(child) }
  end

  def blank?(node)
    (node.text? && node.content.strip == "") || (node.element? && node.name == "br")
  end
end
