# Attributes a page view to an AI assistant when the browser sent no referrer.
#
# Assistants often open links with `rel=noreferrer`, so `document.referrer` is
# empty. Several of them (ChatGPT first of all) tag the link with
# `utm_source=<their domain>` instead. Fastly strips `utm_source` before the
# request reaches the origin (see config/fastly/snippets/safe_params_list.vcl),
# so only the browser can see it and send it with the page view.
#
# Only known assistant domains are accepted, so a crafted link cannot write
# arbitrary domains into referrer analytics.
module AiAssistantReferral
  DOMAINS = %w[
    chatgpt.com
    chat.openai.com
    perplexity.ai
    claude.ai
    gemini.google.com
    copilot.microsoft.com
    grok.com
    chat.deepseek.com
    chat.mistral.ai
    meta.ai
    you.com
    phind.com
  ].freeze

  # @param utm_source [String, nil] the utm_source value from the landing URL
  # @return [String, nil] a referrer URL for a known assistant, otherwise nil
  def self.referrer_for(utm_source)
    return if utm_source.blank?

    domain = utm_source.to_s.strip.downcase
      .delete_prefix("https://").delete_prefix("http://")
      .delete_prefix("www.").delete_suffix("/")
    return unless DOMAINS.include?(domain)

    "https://#{domain}/"
  end
end
