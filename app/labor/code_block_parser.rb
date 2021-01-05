module CodeBlockParser
  include InlineSvg::ActionView::Helpers
  include ApplicationHelper

  def remove_nested_linebreak_in_list(html)
    html_doc = Nokogiri::HTML(html)
    html_doc.xpath("//*[self::ul or self::ol or self::li]/br").each(&:remove)
    html_doc.to_html
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

  def wrap_all_images_in_links(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.search("p img").each do |image|
      next if image.parent.name == "a"

      image.swap("<a href='#{image.attr('src')}' class='article-body-image-wrapper'>#{image}</a>")
    end
    doc.to_html
  end

  def add_control_class_to_codeblock(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.search("div.highlight").each do |codeblock|
      codeblock.add_class("js-code-highlight")
    end
    doc.to_html
  end

  def add_control_panel_to_codeblock(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.search("div.highlight").each do |codeblock|
      codeblock.add_child('<div class="highlight__panel js-actions-panel"></div>')
    end
    doc.to_html
  end

  def add_fullscreen_button_to_panel(html)
    on_title = "Enter fullscreen mode"
    on_cls = "highlight-action highlight-action--fullscreen-on"
    icon_fullscreen_on = inline_svg_tag("fullscreen-on.svg", class: on_cls, title: on_title)
    off_title = "Exit fullscreen mode"
    off_cls = "highlight-action highlight-action--fullscreen-off"
    icon_fullscreen_off = inline_svg_tag("fullscreen-off.svg", class: off_cls, title: off_title)
    doc = Nokogiri::HTML.fragment(html)
    doc.search("div.highlight__panel").each do |codeblock|
      fullscreen_action = <<~HTML
        <div class="highlight__panel-action js-fullscreen-code-action">
            #{icon_fullscreen_on}
            #{icon_fullscreen_off}
        </div>
      HTML

      codeblock.add_child(fullscreen_action)
    end
    doc.to_html
  end

  def wrap_all_tables(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.search("table").each { |table| table.swap("<div class='table-wrapper-paragraph'>#{table}</div>") }
    doc.to_html
  end

  def remove_empty_paragraphs(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.css("p").select { |paragraph| all_children_are_blank?(paragraph) }.each(&:remove)
    doc.to_html
  end

  def escape_colon_emojis_in_codeblock(html)
    html_doc = Nokogiri::HTML.fragment(html)

    html_doc.children.each do |el|
      next if el.name == "code"

      if el.search("code").empty?
        el.swap(Html::ParseEmoji.call(el.to_html))
      else
        el.children = escape_colon_emojis_in_codeblock(el.children.to_html)
      end
    end
    html_doc.to_html
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
end
