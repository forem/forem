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
      html_doc.xpath("//*[self::ul or self::ol or self::li]/br").each(&:remove) if @html&.match?(/<br/i)
      @html = html_doc.to_html

      self
    end

    def prefix_all_images(width: 880, synchronous_detail_detection: false, quality: "auto")
      # wrap with Cloudinary or allow if from giphy or githubusercontent.com
      doc = Nokogiri::HTML.fragment(@html)

      if @html&.match?(/<img/i)
        doc.css("img").each do |img|
          src = img.attr("src")
          next unless src
          # allow image to render as-is
          next if allowed_image_host?(src)
          next if img["data-ignore-prefix"] == "true"

          if synchronous_detail_detection
            header = { "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})" }
            img["width"], img["height"] = FastImage.size(src, timeout: 10, http_header: header)
          end

          img["loading"] = "lazy"
          img["src"] = if Giphy::Image.valid_url?(src)
                         src.gsub("https://media.", "https://i.")
                       else
                         img_of_size(src, width, quality: quality)
                       end
        end
      end

      @html = doc.to_html

      self
    end

    def wrap_all_images_in_links
      return self if @html.blank? || !@html.match?(/<img/i)

      @html = ForemNative.wrap_all_images_in_links(@html) ||
        legacy_wrap_all_images_in_links

      self
    end

    def add_control_class_to_codeblock
      return self if @html.blank? || !may_contain?("highlight")

      @html = ForemNative.add_control_class_to_codeblock(@html) ||
        legacy_add_control_class_to_codeblock

      self
    end

    def add_control_panel_to_codeblock
      return self if @html.blank? || !may_contain?("highlight")

      @html = ForemNative.add_control_panel_to_codeblock(@html) ||
        legacy_add_control_panel_to_codeblock

      self
    end

    def add_fullscreen_button_to_panel
      return self if @html.blank? || !may_contain?("highlight__panel")

      on_title = I18n.t("services.html.parser.enter_fullscreen_mode")
      on_cls = "highlight-action crayons-icon highlight-action--fullscreen-on"
      icon_fullscreen_on = inline_svg_tag(
        "fullscreen-on.svg", class: on_cls, title: on_title, width: "20px", height: "20px"
      )
      off_title = I18n.t("services.html.parser.exit_fullscreen_mode")
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
      return self if @html.blank? || !@html.match?(/<table/i)

      @html = ForemNative.wrap_all_tables(@html) ||
        legacy_wrap_all_tables

      self
    end

    def remove_empty_paragraphs
      return self if @html.blank? || !@html.match?(/<p/i)

      @html = ForemNative.remove_empty_paragraphs(@html) ||
        legacy_remove_empty_paragraphs

      self
    end

    def escape_colon_emojis_in_codeblock
      @html = ForemNative.escape_colon_emojis_in_codeblock(@html) ||
        legacy_escape_colon_emojis_in_codeblock

      self
    end

    def unescape_raw_tag_in_codeblocks
      return self if @html.blank?

      @html = ForemNative.unescape_raw_tag_in_codeblocks(@html) ||
        legacy_unescape_raw_tag_in_codeblocks

      self
    end

    def wrap_all_figures_with_tags
      return self if @html.blank? || !@html.match?(/<figcaption/i)

      html_doc = Nokogiri::HTML(@html)

      html_doc.xpath("//figcaption").each do |caption|
        next if caption.parent.name == "figure"
        next unless caption.previous_element

        fig = html_doc.create_element "figure"
        prev = caption.previous_element
        prev.replace(fig) << prev << caption
      end

      body = html_doc.at_css("body")
      @html = body ? body.inner_html : html_doc.to_html

      self
    end

    def wrap_mentions_with_links
      return self if @html.blank? || !may_contain?("@")

      @html = native_wrap_mentions_with_links ||
        legacy_wrap_mentions_with_links

      self
    end

    def parse_emojis
      return self if @html.blank?

      @html = ForemNative.parse_emojis(@html) || legacy_parse_emojis

      self
    end

    def enforce_gif_like_videos
      return self if @html.blank? || !@html.match?(/<video/i)

      doc = Nokogiri::HTML.fragment(@html)

      doc.css("video").each do |video|
        # Mark as gif-like for JS to attach behavior
        video["data-gif-video"] = "true"
        # Default attributes to mimic GIF behavior, unless explicitly overridden
        video["autoplay"] = video["autoplay"] || "autoplay"
        video["loop"] = video["loop"] || "loop"
        video["muted"] = video["muted"] || "muted"
        video["playsinline"] = video["playsinline"] || "playsinline"
        # Remove controls by default unless explicitly present
        video.remove_attribute("controls") unless video["controls"]
        # Avoid preloading to save bandwidth if not provided
        video["preload"] = video["preload"] || "metadata"
      end

      @html = doc.to_html

      self
    end

    private

    # Literal-substring fast-exit guard. Any "&" means the marker may be spelled with
    # character references (e.g. "&#64;" or "high&#108;ight") that Nokogiri decodes,
    # so fall through to the full parse in that case.
    def may_contain?(marker)
      @html.include?(marker) || @html.include?("&")
    end

    def img_of_size(source, width = 880, quality: "auto")
      Images::Optimizer.call(source, width: width, quality: quality).gsub(",", "%2C")
    end

    def all_children_are_blank?(node)
      node.children.all? { |child| blank?(child) }
    end

    def blank?(node)
      (node.text? && node.content.strip == "") || (node.element? && node.name == "br")
    end

    def allowed_image_host?(src)
      ImageUri.new(src).allowed?
    end

    def user_link_if_exists(mention)
      username = mention.delete("@").downcase
      if User.find_by(username: username)
        <<~HTML.chomp
          <a class='mentioned-user' href='#{ApplicationConfig['APP_PROTOCOL']}#{Settings::General.app_domain}/#{username}'>@#{username}</a>
        HTML
      else
        mention
      end
    end

    def possibly_raw_tag_syntax?(array)
      (RAW_TAG_DELIMITERS & array).any?
    end

    def legacy_wrap_all_images_in_links
      doc = Nokogiri::HTML.fragment(@html)

      doc.search("p img").each do |image|
        next if image.parent.name == "a"

        link = doc.document.create_element("a")
        link["href"] = image.attr("src").to_s
        link["class"] = "article-body-image-wrapper"
        image.replace(link)
        link.add_child(image)
      end

      doc.to_html
    end

    def legacy_add_control_class_to_codeblock
      doc = Nokogiri::HTML.fragment(@html)

      doc.search("div.highlight").each do |codeblock|
        codeblock.add_class("js-code-highlight")
      end

      doc.to_html
    end

    def legacy_add_control_panel_to_codeblock
      doc = Nokogiri::HTML.fragment(@html)

      doc.search("div.highlight").each do |codeblock|
        codeblock.add_child('<div class="highlight__panel js-actions-panel"></div>')
      end

      doc.to_html
    end

    def legacy_wrap_all_tables
      doc = Nokogiri::HTML.fragment(@html)
      doc.search("table").each { |table| table.swap("<div class='table-wrapper-paragraph'>#{table}</div>") }
      doc.to_html
    end

    def legacy_remove_empty_paragraphs
      doc = Nokogiri::HTML.fragment(@html)
      doc.css("p").select { |paragraph| all_children_are_blank?(paragraph) }.each(&:remove)
      doc.to_html
    end

    def legacy_unescape_raw_tag_in_codeblocks
      html = @html.gsub(RAW_TAG, "{% raw %}").gsub(END_RAW_TAG, "{% endraw %}")
      html_doc = Nokogiri::HTML(html)
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

      body = html_doc.at_css("body")
      body ? body.inner_html : html_doc.to_html
    end

    def native_wrap_mentions_with_links
      usernames = ForemNative.extract_mention_usernames(@html)
      return unless usernames

      existing = usernames.select { |u| User.find_by(username: u) }
      base_url = "#{ApplicationConfig['APP_PROTOCOL']}#{Settings::General.app_domain}"
      ForemNative.wrap_mentions_with_links(@html, existing, base_url)
    end

    def legacy_wrap_mentions_with_links
      html_doc = Nokogiri::HTML(@html)

      # looks for nodes that isn't <code>, <a>, and contains "@"
      targets = html_doc.xpath('//html/body/*[not (self::code) and not(self::a) and contains(., "@")]').to_a

      # A Queue system to look for and replace possible usernames
      until targets.empty?
        node = targets.shift

        # only focus on portion of text with "@"
        node.xpath("text()[contains(.,'@')]").each do |el|
          el.replace(el.to_s.gsub(/\B@[a-z0-9_-]+/i) { |text| user_link_if_exists(text) })
        end

        # enqueue children that has @ in it's text
        children = node.xpath('*[not(self::code) and not(self::a) and contains(., "@")]').to_a
        targets.concat(children)
      end

      body = html_doc.at_css("body")
      body ? body.inner_html : html_doc.to_html
    end

    def legacy_escape_colon_emojis_in_codeblock
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

      html_doc.to_html
    end

    # Handles non-plain-String inputs (such as ActiveSupport::SafeBuffer or non-UTF-8 strings)
    # using the embedded gemoji lookup table in ForemNative (see `crates/forem_core/src/emoji_data.rs`).
    def legacy_parse_emojis
      @html.gsub!(/:([\w+-]+):/) do |match|
        ForemNative.emoji_by_alias(Regexp.last_match(1)) || match
      end
      @html
    end
  end
end
