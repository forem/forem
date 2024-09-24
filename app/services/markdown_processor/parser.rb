module MarkdownProcessor
  class Parser
    BAD_XSS_REGEX = [
      /src=["'](data|&)/i,
      %r{data:text/html[,;][\sa-z0-9]*}i,
    ].freeze

    CODE_BLOCKS_REGEX = /(~{3}|`{3}|`{2}|`)[\s\S]*?\1/

    WORDS_READ_PER_MINUTE = 275.0

    # @param content [String] The user input, mix of markdown and liquid.  This might be an
    #        article's markdown body.
    # @param source [Object] The thing associated with the content.  This might be an article.
    # @param user [User] Who's the one writing the content?
    # @param liquid_tag_options [Hash]
    #
    # @note This is a place to pass in a different policy object.  But like, maybe don't do
    #       that with user input, but perhaps via a data migration script.
    #
    # @see LiquidTagBase for more information regarding the liquid tag options.

    def initialize(content, source: nil, user: nil,
                   liquid_tag_options: {})
      @content = content
      @source = source
      @user = user
      @liquid_tag_options = liquid_tag_options.merge({ source: @source, user: @user })
    end

    # @param prefix_images_options [Hash] params, that need to be passed further to HtmlParser#prefix_all_images
    def finalize(link_attributes: {}, prefix_images_options: { width: 800, synchronous_detail_detection: false })
      options = { hard_wrap: true, filter_html: false, link_attributes: link_attributes }
      renderer = Redcarpet::Render::HTMLRouge.new(options)
      markdown = Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG)
      catch_xss_attempts(@content)
      code_tag_content = convert_code_tags_to_triple_backticks(@content)
      escaped_content = escape_liquid_tags_in_codeblock(code_tag_content)
      html = markdown.render(escaped_content)
      sanitized_content = ActionController::Base.helpers.sanitize html, { scrubber: RenderedMarkdownScrubber.new }

      begin
        # NOTE: [@rhymes] liquid 5.0.0 does not support ActiveSupport::SafeBuffer,
        # a String substitute, hence we force the conversion before passing it to Liquid::Template.
        # See <https://github.com/Shopify/liquid/issues/1390>
        parsed_liquid = Liquid::Template.parse(sanitized_content.to_str, @liquid_tag_options)
        html = markdown.render(parsed_liquid.render)
      rescue Liquid::SyntaxError => e
        html = e.message
      end

      html = add_target_blank_to_outbound_links(html)
      parse_html(html, prefix_images_options)
    end

    def add_target_blank_to_outbound_links(html)
      app_domain = Settings::General.app_domain
      doc = Nokogiri::HTML.fragment(html)
      doc.css('a[href^="http"]').each do |link|
        href = link["href"]
        next unless href&.exclude?(app_domain)

        link[:target] = "_blank"
        existing_rel = link[:rel]
        new_rel = %w[noopener noreferrer]
        if existing_rel
          existing_rel_values = existing_rel.split
          new_rel = (existing_rel_values + new_rel).uniq.join(" ")
        else
          new_rel = new_rel.join(" ")
        end
        link[:rel] = new_rel
      end
      doc.to_html
    end

    def calculate_reading_time
      word_count = @content.split(/\W+/).count
      (word_count / WORDS_READ_PER_MINUTE).ceil
    end

    def evaluate_markdown(allowed_tags: MarkdownProcessor::AllowedTags::MARKDOWN_PROCESSOR_DEFAULT)
      return if @content.blank?

      renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
      markdown = Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG)
      ActionController::Base.helpers.sanitize(markdown.render(@content),
                                              tags: allowed_tags,
                                              attributes: MarkdownProcessor::AllowedAttributes::MARKDOWN_PROCESSOR)
    end

    def evaluate_limited_markdown(allowed_tags: MarkdownProcessor::AllowedTags::MARKDOWN_PROCESSOR_LIMITED)
      evaluate_markdown(allowed_tags: allowed_tags)
    end

    # rubocop:disable Layout/LineLength
    def evaluate_inline_limited_markdown(allowed_tags: MarkdownProcessor::AllowedTags::MARKDOWN_PROCESSOR_INLINE_LIMITED)
      evaluate_markdown(allowed_tags: allowed_tags)
    end
    # rubocop:enable Layout/LineLength

    def evaluate_listings_markdown(allowed_tags: MarkdownProcessor::AllowedTags::MARKDOWN_PROCESSOR_LISTINGS)
      evaluate_markdown(allowed_tags: allowed_tags)
    end

    def tags_used
      return [] if @content.blank?

      cleaned_parsed = escape_liquid_tags_in_codeblock(@content)
      tags = []
      liquid_tag_options = { source: @source, user: @user }
      Liquid::Template.parse(cleaned_parsed, liquid_tag_options).root.nodelist.each do |node|
        tags << node.class if node.class.superclass.to_s == LiquidTagBase.to_s
      end
      tags.uniq
    rescue Liquid::SyntaxError
      []
    end

    def catch_xss_attempts(markdown)
      markdown_without_code_blocks = markdown.gsub(CODE_BLOCKS_REGEX, "")
      return unless markdown_without_code_blocks.match?(Regexp.union(BAD_XSS_REGEX))

      raise ArgumentError, I18n.t("services.markdown_processor.parser.invalid_markdown_detected")
    end

    def escape_liquid_tags_in_codeblock(content)
      pos = 0
      # arrays regarding positioning of tildes, ticks, and sin
      arrTilde = []
      arrTick = []
      arr1Or2Ticks = []
      firstTick = true
      firstTilde = true

      highest_ticks = {} # if number of ticks is 3+ then we opened a codeblock
      highest_tildes = {}
      contentDup = content.dup
      contentDup.gsub!("{% endraw %}", "{----% endraw %----}")
      contentDup.gsub!("{% raw %}", "{----% raw %----}")
      regex = /[[:space:]]*(~{3,}).*?|[[:space:]]*(`{3,}).*?|(`{2}.+?`{2})|(`{1}.+?`{1})/m
      contentDup.scan(regex) do |codeblock|
        match_data = Regexp.last_match
        start_pos = match_data.begin(0)
        end_pos = match_data.end(0)
        # It should be as
        # ```
        # {% raw %}
        # blah blah blah
        # {% endraw %}
        # ```... (3+ ticks)
        if ::Regexp.last_match(1)
          tilde = {}
          tilde[0] = ::Regexp.last_match(1).length
          tilde[1] = "\n{% raw %}\n"
          index1 = contentDup.index("~", start_pos)
          index2 = contentDup.index(/\s/, index1) # find the position of the nearest whitespace after the tildes
          tilde[2] = index2
          if firstTick
            if firstTilde # if there is already are 3+ ticks that hasn't been closed, then no {% raw %} should be added with the tildes
              firstTilde = false
              arrTilde.push(tilde)
              highest_tildes = tilde
            elsif !firstTilde
              if tilde[0] >= highest_tildes[0]
                tilde[1] = "\n{% endraw %}\n"
                tilde[2] = end_pos - tilde[0] # because we want to put the {% endraw %} before the tildes
                arrTilde.push(tilde)
                firstTilde = true
              end
            end
          end
          # same stuff here but using ticks instead of tildes
        elsif ::Regexp.last_match(2)
          tick = {}
          tick[0] = ::Regexp.last_match(2).length
          tick[1] = "\n{% raw %}\n"
          index1 = contentDup.index("`", start_pos)
          index2 = contentDup.index(/\s/, index1)
          tick[2] = index2
          if firstTilde
            if firstTick
              firstTick = false
              arrTick.push(tick)
              highest_ticks = tick
            elsif tick[0] >= highest_ticks[0]
              tick[1] = "\n{% endraw %}\n"
              tick[2] = end_pos - tick[0]
              arrTick.push(tick)
              firstTick = true

            end
          end

        elsif ::Regexp.last_match(3)
          doubleTick = {}
          doubleTick[2] = start_pos
          doubleTick[1] = end_pos
          arr1Or2Ticks.push(doubleTick)
        elsif ::Regexp.last_match(4)
          # p $4
          # p start_pos
          # p end_pos
          doubleTick = {}
          doubleTick[2] = start_pos
          doubleTick[1] = end_pos
          arr1Or2Ticks.push(doubleTick)
        end
        pos = end_pos
      end
      arr = []
      count = 0
      arrTick.each do |tick|
        arr.push(tick)
      end
      arrTilde.each do |tilde|
        arr.push(tilde)
      end
      arr1Or2Ticks.each do |dbTick|
        arr.push(dbTick)
      end
      # pushing into one array to sort by position.
      # Addition of escaped liquid tags alters the positioning of subsequent escaped liquid tags
      # Therefore, it is best to start from the first positiion to the last
      arr.sort_by! { |a| a[2] }
      arr.each do |item|
        if item.key?(0) # if it is a 3+ tilde or tick
          contentDup.insert(item[2] + count, item[1])
          count += item[1].length # keeps track of the shift
        else
          contentDup.insert(item[2] + count, "{% raw %}")
          count += "{% raw %}".length
          contentDup.insert(item[1] + count, "{% endraw %}")
          count += "{% endraw %}".length
        end
      end
      contentDup
      # return content
    end

    def convert_code_tags_to_triple_backticks(content)
      # return content if there is not a <code> tag
      return content unless /^<code>$/.match?(content)

      # return content if there is a <pre> and <code> tag
      return content if content.include?("<code>") && content.include?("<pre>")

      # Convert all multiline code tags to triple backticks
      content.gsub(%r{^</?code>$}, "\n```\n")
    end

    private

    def parse_html(html, prefix_images_options)
      return html if html.blank?

      Html::Parser
        .new(html)
        .remove_nested_linebreak_in_list
        .prefix_all_images(**prefix_images_options)
        .wrap_all_images_in_links
        .add_control_class_to_codeblock
        .add_control_panel_to_codeblock
        .add_fullscreen_button_to_panel
        .wrap_all_tables
        .remove_empty_paragraphs
        .escape_colon_emojis_in_codeblock
        .unescape_raw_tag_in_codeblocks
        .wrap_all_figures_with_tags
        .wrap_mentions_with_links
        .html
    end
  end
end
