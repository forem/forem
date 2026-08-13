class LegacyCodeTag < Liquid::Block
  def self.fallback_html(preamble:, parsed_content:)
    escaped_preamble = ERB::Util.html_escape(preamble)
    escaped_content = ERB::Util.html_escape(parsed_content)

    html = +''
    html << '<div class="ltag-legacy-code-fallback crayons-notice crayons-notice--warning">'
    html << '<p>This code block is no longer available. The original code is shown below.</p>'
    if preamble.present?
      html << '<pre class="ltag-legacy-code-fallback__preamble"><code>'
      html << escaped_preamble
      html << '</code></pre>'
    end
    html << '<pre class="ltag-legacy-code-fallback__code"><code>'
    html << escaped_content
    html << '</code></pre>'
    html << '</div>'
    html
  end

  def initialize(_tag_name, markup, _parse_context)
    super
    @preamble = sanitized_preamble(markup)
  end

  def render(context)
    content = Nokogiri::HTML.parse(super)
    parsed_content = content.xpath("//html/body").text

    self.class.fallback_html(
      preamble: @preamble,
      parsed_content: parsed_content,
    )
  end

  def sanitized_preamble(markup)
    raise StandardError, I18n.t("liquid_tags.legacy_code_tag.invalid_tag") if markup.include? ">"

    ActionView::Base.full_sanitizer.sanitize(markup, tags: [])
  end
end

Liquid::Template.register_tag("runkit", LegacyCodeTag)
