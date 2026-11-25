# Final non-database-driven adjustments applied to stored `processed_html` at read time, so we can
# avoid reprocessing every record for a rendering change:
#
# * Swaps `PRIOR_CLOUDFLARE_IMAGES_DOMAIN` for `CLOUDFLARE_IMAGES_DOMAIN` (the Cloudflare Images
#   domain migration) through `ForemNative.gsub_literal`. When the prior domain does not appear,
#   it hands back the stored string instead of copying the whole document.
# * Optionally (Article and Comment) re-renders legacy `{% runkit %}` embeds as static code blocks.
#
# Including models can override `finalize_legacy_code_html?` to skip the runkit pass (Billboard).
module ProcessedHtmlFinalizable
  extend ActiveSupport::Concern

  LEGACY_CODE_MARKER = "runkit-element".freeze

  def self.rewrite_cloudflare_images_domain(html)
    prior_domain = ApplicationConfig["PRIOR_CLOUDFLARE_IMAGES_DOMAIN"]
    current_domain = ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"]
    return html if prior_domain.blank? || current_domain.blank?

    ForemNative.gsub_literal(html, prior_domain, current_domain) || html.gsub(prior_domain, current_domain)
  end

  def processed_html_final
    html = processed_html
    html = replace_legacy_code_html(html) if finalize_legacy_code_html?
    ProcessedHtmlFinalizable.rewrite_cloudflare_images_domain(html)
  end

  private

  def finalize_legacy_code_html?
    true
  end

  # Also called directly (via `__send__`) by the native comment tree and story card renderers.
  def replace_legacy_code_html(html)
    return html if html.blank?
    return html unless html.include?(LEGACY_CODE_MARKER)

    fragment = Nokogiri::HTML.fragment(html)
    fragment.css(".runkit-element").each do |element|
      preamble = element.at_css("code:nth-of-type(1)")&.text.to_s
      content = element.at_css("code:nth-of-type(2)")&.text.to_s

      replacement_html = LegacyCodeTag.fallback_html(
        preamble: preamble,
        parsed_content: content,
      )

      element.replace(Nokogiri::HTML.fragment(replacement_html))
    end

    fragment.to_html
  rescue StandardError
    html
  end
end
