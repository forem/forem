module MarkdownProcessor
  class Parser
    include ApplicationHelper

    BAD_XSS_REGEX = [
      /src=["'](data|&)/i,
      %r{data:text/html[,;][\sa-z0-9]*}i,
    ].freeze

    WORDS_READ_PER_MINUTE = 275.0

    def initialize(content, source: nil, user: nil)
      @content = content
      @source = source
      @user = user
    end

    def finalize(link_attributes: {})
      options = { hard_wrap: true, filter_html: false, link_attributes: link_attributes }
      renderer = Redcarpet::Render::HTMLRouge.new(options)
      markdown = Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG)
      catch_xss_attempts(@content)
      escaped_content = escape_liquid_tags_in_codeblock(@content)
      html = markdown.render(escaped_content)
      sanitized_content = sanitize_rendered_markdown(html)
      begin
        liquid_tag_options = { source: @source, user: @user }

        # NOTE: [@rhymes] liquid 5.0.0 does not support ActiveSupport::SafeBuffer,
        # a String substitute, hence we force the conversion before passing it to Liquid::Template.
        # See <https://github.com/Shopify/liquid/issues/1390>
        parsed_liquid = Liquid::Template.parse(sanitized_content.to_str, liquid_tag_options)

        html = markdown.render(parsed_liquid.render)
      rescue Liquid::SyntaxError => e
        html = e.message
      end

      parse_html(html)
    end

    def calculate_reading_time
      word_count = @content.split(/\W+/).count
      (word_count / WORDS_READ_PER_MINUTE).ceil
    end

    def evaluate_markdown
      return if @content.blank?

      renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
      markdown = Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG)
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
      markdown = Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG)
      allowed_tags = %w[strong i u b em p br code]
      allowed_attributes = %w[href strong em ref rel src title alt class]
      ActionController::Base.helpers.sanitize markdown.render(@content),
                                              tags: allowed_tags,
                                              attributes: allowed_attributes
    end

    def evaluate_inline_limited_markdown
      return if @content.blank?

      renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
      markdown = Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG)
      allowed_tags = %w[strong i u b em code]
      allowed_attributes = %w[href strong em ref rel src title alt class]
      ActionController::Base.helpers.sanitize markdown.render(@content),
                                              tags: allowed_tags,
                                              attributes: allowed_attributes
    end

    def evaluate_listings_markdown
      return if @content.blank?

      renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
      markdown = Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG)
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
      liquid_tag_options = { source: @source, user: @user }
      Liquid::Template.parse(cleaned_parsed, liquid_tag_options).root.nodelist.each do |node|
        tags << node.class if node.class.superclass.to_s == LiquidTagBase.to_s
      end
      tags.uniq
    rescue Liquid::SyntaxError
      []
    end

    def catch_xss_attempts(markdown)
      return unless markdown.match?(Regexp.union(BAD_XSS_REGEX))

      raise ArgumentError, "Invalid markdown detected"
    end

    def escape_liquid_tags_in_codeblock(content)
      # Escape codeblocks, code spans, and inline code
      content.gsub(/[[:space:]]*`{3}.*?`{3}|`{2}.+?`{2}|`{1}.+?`{1}/m) do |codeblock|
        codeblock.gsub!("{% endraw %}", "{----% endraw %----}")
        codeblock.gsub!("{% raw %}", "{----% raw %----}")
        if codeblock.match?(/[[:space:]]*`{3}/)
          "\n{% raw %}\n#{codeblock}\n{% endraw %}\n"
        else
          "{% raw %}#{codeblock}{% endraw %}"
        end
      end
    end

    private

    def parse_html(html)
      return html if html.blank?

      Html::Parser
        .new(html)
        .remove_nested_linebreak_in_list
        .prefix_all_images
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
