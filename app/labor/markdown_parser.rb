class MarkdownParser
  include ApplicationHelper
  include CodeBlockParser

  BAD_XSS_REGEX = [
    /src=["'](data|&)/i,
    %r{data:text/html[,;][\sa-z0-9]*}i,
  ].freeze

  WORDS_READ_PER_MINUTE = 275.0

  RAW_TAG_DELIMITERS = ["{", "}", "raw", "endraw", "----"].freeze

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
      parsed_liquid = Liquid::Template.parse(sanitized_content, liquid_tag_options)
      html = markdown.render(parsed_liquid.render)
    rescue Liquid::SyntaxError => e
      html = e.message
    end
    html = remove_nested_linebreak_in_list(html)
    html = prefix_all_images(html)
    html = wrap_all_images_in_links(html)
    html = add_control_class_to_codeblock(html)
    html = add_control_panel_to_codeblock(html)
    html = add_fullscreen_button_to_panel(html)
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

  def allowed_image_host?(src)
    # GitHub camo image won't parse but should be safe to host direct
    src.start_with?("https://camo.githubusercontent.com")
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

  def possibly_raw_tag_syntax?(array)
    (RAW_TAG_DELIMITERS & array).any?
  end

  def user_link_if_exists(mention)
    username = mention.delete("@").downcase
    if User.find_by(username: username)
      <<~HTML
        <a class='comment-mentioned-user' href='#{ApplicationConfig['APP_PROTOCOL']}#{SiteConfig.app_domain}/#{username}'>@#{username}</a>
      HTML
    else
      mention
    end
  end

  def img_of_size(source, width = 880)
    Images::Optimizer.call(source, width: width).gsub(",", "%2C")
  end

  def all_children_are_blank?(node)
    node.children.all? { |child| blank?(child) }
  end

  def blank?(node)
    (node.text? && node.content.strip == "") || (node.element? && node.name == "br")
  end
end
