module Ai
  class EmailDigestSummary
    def initialize(articles, ai_client: nil)
      @articles = articles
      @ai_client = ai_client || Ai::Base.new
    end

    MAX_RETRIES = 1

    def generate
      return if @articles.empty?

      Rails.cache.fetch(cache_key, expires_in: 7.days) do
        generate_with_retry
      end
    rescue StandardError => e
      Rails.logger.error("AI Digest Summary generation failed: #{e.class} - #{e.message}")
      nil
    end

    private

    def generate_with_retry
      attempts = 0
      current_prompt = prompt

      loop do
        attempts += 1
        output = @ai_client.call(current_prompt)
        
        if valid_markdown?(output)
          return output
        elsif attempts <= MAX_RETRIES
          Rails.logger.warn("AI Digest Summary received invalid markdown. Retrying (Attempt #{attempts}/#{MAX_RETRIES}).")
          current_prompt = prompt + "\n\nIMPORTANT: Your previous output contained HTML tag attributes or raw HTML. Please strictly use Markdown only. Do not use <a> tags."
        else
          Rails.logger.error("AI Digest Summary failed validation after #{attempts} attempts. Output: #{output.to_s.truncate(100)}")
          return nil
        end
      end
    end

    def valid_markdown?(text)
      return false if text.blank?
      
      # Check for common raw HTML tags that shouldn't be there
      # We allow safe tags if strictly necessary, but for this summary we want pure markdown.
      # Detecting <p>, <div>, <a>, <br>, <strong> with attributes
      return false if text.match?(/<[a-z][\s\S]*>/i)

      # Check for malformed markdown links that look like [text](<a href...)
      return false if text.match?(/\[.*\]\(<a\s+href/)

      true
    end

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
        - STRICTLY NO HTML. Do not use <p>, <a>, or any other HTML tags. Use standard Markdown only.
        - Ensure links are well-formed Markdown: [Link Text](https://example.com).
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
