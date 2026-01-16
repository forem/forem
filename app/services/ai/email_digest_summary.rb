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
      # Sort IDs to ensure order-independence
      sorted_ids = @articles.map(&:id).sort.join("-")
      "ai_digest_summary_v1_#{Digest::MD5.hexdigest(sorted_ids)}"
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
        1. Provides an overview of the key themes covered in these articles.
        2. Explains how these themes connect or run together.
        3. Offers a brief perspective on why this specific collection of articles is interesting.

        Guidelines:
        - Keep it very concise and not overly wordy.
        - Use markdown **bold links** like **[Article Title](URL)** when mentioning the key themes and articles.
        - Output should be markup with these links embedded naturally in the flow.
        - Do not use any headers (like # or ##).
        - Do not list each article one by one; focus on the synthesis of the themes.

        Articles:
        #{article_list}

        Please provide the summary now:
      PROMPT
    end
  end
end
