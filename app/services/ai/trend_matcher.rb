module Ai
  ##
  # Analyzes an article and checks if it applies to any current trends
  # for the article's subforem.
  class TrendMatcher
    # @param article [Article] The article to check for trend matching.
    def initialize(article)
      @ai_client = Ai::Base.new
      @article = article
    end

    ##
    # Finds the first current trend that matches the article.
    # Returns nil if no matching trend is found.
    #
    # @return [Trend, nil] The first matching trend, or nil if none found.
    def find_matching_trend
      return unless @article.subforem_id.present?

      current_trends = Trend.current.for_subforem(@article.subforem_id)
      return if current_trends.empty?

      # Check each trend to see if the article matches
      current_trends.each do |trend|
        return trend if article_matches_trend?(trend)
      end

      nil
    end

    private

    attr_reader :ai_client, :article

    ##
    # Uses AI to determine if the article matches a specific trend.
    #
    # @param trend [Trend] The trend to check against
    # @return [Boolean] True if the article matches the trend, false otherwise
    def article_matches_trend?(trend)
      return false unless Ai::Base::DEFAULT_KEY.present?

      prompt = build_trend_matching_prompt(trend)

      begin
        response = ai_client.call(prompt)
        parse_trend_response(response)
      rescue StandardError => e
        Rails.logger.error("AI trend matching failed for article #{article.id}, trend #{trend.id}: #{e}")
        false
      end
    end

    ##
    # Builds the prompt for AI to match the article with a trend.
    #
    # @param trend [Trend] The trend to match against
    # @return [String] The prompt to be sent to the AI
    def build_trend_matching_prompt(trend)
      article_context = build_article_context
      trend_context = build_trend_context(trend)

      <<~PROMPT
        Analyze the following article and determine if it applies to the given trend.

        **Article to Analyze:**
        #{article_context}

        **Trend Information:**
        #{trend_context}

        **Instructions:**
        1. Read the trend's full content description carefully
        2. Determine if the article's content, topic, and purpose align with the trend
        3. Consider whether the article meaningfully relates to the trend's focus
        4. Only respond with "YES" if the article genuinely applies to this trend
        5. If the article does not apply, respond with "NO"

        Respond with ONLY "YES" or "NO".
      PROMPT
    end

    ##
    # Builds context about the article for the AI prompt.
    #
    # @return [String] Article context information
    def build_article_context
      <<~CONTEXT
        Title: #{article.title}
        Body: #{article.body_markdown}
      CONTEXT
    end

    ##
    # Builds context about the trend for the AI prompt.
    #
    # @param trend [Trend] The trend to build context for
    # @return [String] Trend context information
    def build_trend_context(trend)
      <<~CONTEXT
        Short Title: #{trend.short_title}
        Public Description: #{trend.public_description}
        Full Content Description: #{trend.full_content_description}
      CONTEXT
    end

    ##
    # Parses the AI's response to determine if the article matches the trend.
    #
    # @param response [String] The text response from the AI
    # @return [Boolean] True if response indicates a match, false otherwise
    def parse_trend_response(response)
      return false if response.blank?

      response.strip.upcase == "YES"
    end
  end
end

