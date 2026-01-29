module Ai
  class EmailDigestSummary
    def initialize(articles, ai_client: nil)
      @articles = articles
      @ai_client = ai_client || Ai::Base.new
    end

    def generate
      return if @articles.empty?

      Rails.cache.fetch(cache_key, expires_in: 7.days) do
        @ai_client.call(prompt)
      end
    rescue StandardError => e
      Rails.logger.error("AI Digest Summary generation failed: #{e.class} - #{e.message}")
      nil
    end

    private

    def cache_key
      # Sort paths to ensure order-independence
      sorted_paths = @articles.map(&:path).sort.join("-")
      "ai_digest_summary_v1_#{Digest::MD5.hexdigest(sorted_paths)}"
    end

    def prompt
      base_url = "https://#{Settings::General.app_domain}"
      article_list = @articles.map do |a|
        "- Title: #{a.title}\n  URL: #{base_url}#{a.path}\n  Description: #{a.description}\n  Tags: #{a.cached_tag_list}"
      end.join("\n\n")

      <<~PROMPT
        You are an insightful technical curator for the DEV community.
        I will provide you with a list of articles from a developer community digest.

        Your task is to write a brief, engaging "Digest Overview" (about 2 short paragraphs) that:
        1. Identifies and describes the most interesting thematic threads in this collection.
        2. Synthesizes how these articles connect or relate to broader trends.

        Guidelines for Selection & Synthesis:
        - You do NOT need to mention every article. Focus on the ones that make the most sense together to draw out compelling themes.

        Guidelines for Formatting:
        - Keep it very concise and not overly wordy.
        - Use markdown **bold links** like **[Keyword/Phrase](URL)** when mentioning themes and articles.
        - Prefer using keywords or phrases that help communicate the themes as the anchor text, rather than just the article titles (unless the title is particularly descriptive or useful for the theme).
        - Output should be markup with these links embedded naturally in the flow.
        - Do not use any headers (like # or ##).
        - Do not list each article one by one; focus on the synthesis.

        Articles:
        #{article_list}

        Please provide the summary now:
      PROMPT
    end
  end
end
