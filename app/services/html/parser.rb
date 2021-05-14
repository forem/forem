module Html
  class Parser
    # Each of the instance methods should return self to support chaining of
    # methods
    # For example:
    #  Html::Parser.
    #    new(html).
    #    remove_nested_linebreak_in_list.
    #    prefix_all_images.
    #    wrap_all_images_in_links.
    #    html

    include InlineSvg::ActionView::Helpers
    include ApplicationHelper

    RAW_TAG_DELIMITERS = ["{", "}", "raw", "endraw", "----"].freeze
    RAW_TAG = "{----% raw %----}".freeze
    END_RAW_TAG = "{----% endraw %----}".freeze

    attr_accessor :html
    private :html=

    def initialize(html)
      @html = html
    end

    def remove_nested_linebreak_in_list
      html_doc = Nokogiri::HTML(@html)
      html_doc.xpath("//*[self::ul or self::ol or self::li]/br").each(&:remove)
      @html = html_doc.to_html

      self
    end

    def prefix_all_images(width = 880)
      # wrap with Cloudinary or allow if from giphy or githubusercontent.com
      doc = Nokogiri::HTML.fragment(@html)

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

      @html = doc.to_html

      self
    end

    def wrap_all_images_in_links
      doc = Nokogiri::HTML.fragment(@html)

      doc.search("p img").each do |image|
        next if image.parent.name == "a"

        image.swap("<a href='#{image.attr('src')}' class='article-body-image-wrapper'>#{image}</a>")
      end

      @html = doc.to_html

      self
    end

    def add_control_class_to_codeblock
      doc = Nokogiri::HTML.fragment(@html)

      doc.search("div.highlight").each do |codeblock|
        codeblock.add_class("js-code-highlight")
      end

      @html = doc.to_html

      self
    end

    def add_control_panel_to_codeblock
      doc = Nokogiri::HTML.fragment(@html)

      doc.search("div.highlight").each do |codeblock|
        codeblock.add_child('<div class="highlight__panel js-actions-panel"></div>')
      end

      @html = doc.to_html

      self
    end

    def add_fullscreen_button_to_panel
      on_title = "Enter fullscreen mode"
      on_cls = "highlight-action crayons-icon highlight-action--fullscreen-on"
      icon_fullscreen_on = inline_svg_tag(
        "fullscreen-on.svg", class: on_cls, title: on_title, width: "20px", height: "20px"
      )
      off_title = "Exit fullscreen mode"
      off_cls = "highlight-action crayons-icon highlight-action--fullscreen-off"
      icon_fullscreen_off = inline_svg_tag(
        "fullscreen-off.svg", class: off_cls, title: off_title, width: "20px", height: "20px"
      )
      doc = Nokogiri::HTML.fragment(@html)
      doc.search("div.highlight__panel").each do |codeblock|
        fullscreen_action = <<~HTML
          <div class="highlight__panel-action js-fullscreen-code-action">
              #{icon_fullscreen_on}
              #{icon_fullscreen_off}
          </div>
        HTML

        codeblock.add_child(fullscreen_action)
      end

      @html = doc.to_html

      self
    end

    def wrap_all_tables
      doc = Nokogiri::HTML.fragment(@html)
      doc.search("table").each { |table| table.swap("<div class='table-wrapper-paragraph'>#{table}</div>") }
      @html = doc.to_html

      self
    end

    def remove_empty_paragraphs
      doc = Nokogiri::HTML.fragment(@html)
      doc.css("p").select { |paragraph| all_children_are_blank?(paragraph) }.each(&:remove)
      @html = doc.to_html

      self
    end

    def escape_colon_emojis_in_codeblock
      html_doc = Nokogiri::HTML.fragment(@html)

      html_doc.children.each do |el|
        next if el.name == "code"

        if el.search("code").empty?
          if el.parent.present?
            parsed_html = Html::Parser.new(el.to_html).parse_emojis.html
            el.swap(parsed_html)
          end
        else
          el.children = self.class.new(el.children.to_html)
            .escape_colon_emojis_in_codeblock
            .html
        end
      end

      @html = html_doc.to_html

      self
    end

    def unescape_raw_tag_in_codeblocks
      return self if @html.blank?

      @html.gsub!(RAW_TAG, "{% raw %}")
      @html.gsub!(END_RAW_TAG, "{% endraw %}")
      html_doc = Nokogiri::HTML(@html)
      html_doc.xpath("//body/div/pre/code").each do |codeblock|
        next unless codeblock.content.include?(RAW_TAG) || codeblock.content.include?(END_RAW_TAG)

        children_content = codeblock.children.map(&:content)
        indices = children_content.size.times.select do |i|
          possibly_raw_tag_syntax?(children_content[i..i + 2])
        end
        indices.each do |i|
          codeblock.children[i].content = codeblock.children[i].content.delete("----")
        end
      end

      @html =
        if html_doc.at_css("body")
          html_doc.at_css("body").inner_html
        else
          html_doc.to_html
        end

      self
    end

    def wrap_all_figures_with_tags
      html_doc = Nokogiri::HTML(@html)

      html_doc.xpath("//figcaption").each do |caption|
        next if caption.parent.name == "figure"
        next unless caption.previous_element

        fig = html_doc.create_element "figure"
        prev = caption.previous_element
        prev.replace(fig) << prev << caption
      end

      @html =
        if html_doc.at_css("body")
          html_doc.at_css("body").inner_html
        else
          html_doc.to_html
        end

      self
    end

    def wrap_mentions_with_links
      html_doc = Nokogiri::HTML(@html)

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

      @html =
        if html_doc.at_css("body")
          html_doc.at_css("body").inner_html
        else
          html_doc.to_html
        end

      self
    end

    def parse_emojis
      return self if @html.blank?

      @html.gsub!(/:([\w+-]+):/) do |match|
        emoji = Emoji.find_by_alias(Regexp.last_match(1)) # rubocop:disable Rails/DynamicFindBy
        emoji.present? ? emoji.raw : match
      end

      self
    end

    private

    def img_of_size(source, width = 880)
      Images::Optimizer.call(source, width: width).gsub(",", "%2C")
    end

    def all_children_are_blank?(node)
      node.children.all? { |child| blank?(child) }
    end

    def blank?(node)
      (node.text? && node.content.strip == "") || (node.element? && node.name == "br")
    end

    def allowed_image_host?(src)
      # GitHub camo image won't parse but should be safe to host direct
      src.start_with?("https://camo.githubusercontent.com")
    end

    def user_link_if_exists(mention)
      username = mention.delete("@").downcase
      if User.find_by(username: username)
        <<~HTML
          <a class='mentioned-user' href='#{ApplicationConfig['APP_PROTOCOL']}#{SiteConfig.app_domain}/#{username}'>@#{username}</a>
        HTML
      else
        mention
      end
    end

    def possibly_raw_tag_syntax?(array)
      (RAW_TAG_DELIMITERS & array).any?
    end
  end
end
