module LiquidTagHelpers
  extend ActiveSupport::Concern

  OPTION_REGEXP = /(\w+)=(?:"([^"]+)"|(\S+))/

  def fully_unescape_html(str)
    prev = nil
    while str != prev
      prev = str
      str = CGI.unescape_html(str)
    end
    str
  end

  def parse_options(markup)
    cleaned = respond_to?(:strip_tags, true) ? strip_tags(markup) : markup
    options = {}
    cleaned.scan(OPTION_REGEXP) do |key, quoted_val, plain_val|
      options[key] = (quoted_val || plain_val).strip
    end
    options
  end

  def render_nested_markdown(content, allowed_tags: MarkdownProcessor::AllowedTags::MARKDOWN_PROCESSOR_DEFAULT,
                             allowed_attributes: MarkdownProcessor::AllowedAttributes::MARKDOWN_PROCESSOR)
    fragment = Nokogiri::HTML.fragment(content)

    # The outer Markdown pass can split a Liquid block across paragraph tags
    # and turn source newlines into <br> elements. Reconstruct Markdown from
    # those direct children before rendering the block body a second time.
    fragment.xpath("./p").each do |paragraph|
      paragraph.replace("\n\n#{paragraph.inner_html}\n\n")
    end

    markdown = fragment.to_html.gsub(%r{<br\s*/?>\r?\n?}, "\n")
    markdown = remove_structural_indentation(markdown).strip
    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    parsed_content = Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG).render(markdown)

    ActionController::Base.helpers.sanitize(
      parsed_content,
      tags: allowed_tags,
      attributes: allowed_attributes,
    )
  end

  def validate_url!(url, option_name = "url")
    return if url.blank?

    uri = URI.parse(url)
    raise StandardError, I18n.t("liquid_tags.invalid_url_scheme", option: option_name) unless %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    raise StandardError, I18n.t("liquid_tags.invalid_url_scheme", option: option_name)
  end

  private

  def remove_structural_indentation(content)
    first_content_line = content.each_line.detect { |line| line.match?(/\S/) }
    indentation = first_content_line&.match(/\A[ \t]*/)&.to_s
    return content if indentation.blank?

    content.each_line.map { |line| line.delete_prefix(indentation) }.join
  end
end
