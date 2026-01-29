module Ai
  ##
  # Analyzes an article to determine if it meets quality criteria for badge awards.
  # This class uses AI to assess whether an article meets specific quality standards
  # based on custom criteria provided.
  class BadgeCriteriaAssessor
    # @param article [Article] The article object to be assessed.
    # @param criteria [String] The quality criteria to check against.
    def initialize(article, criteria:)
      @ai_client = Ai::Base.new
      @article = article
      @criteria = criteria
    end

    ##
    # Asks the AI if the article meets the quality criteria.
    #
    # @return [Boolean] true if the article qualifies, false otherwise.
    def qualifies?
      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Badge Criteria Assessment failed: #{e}")
      # Fallback to false if AI assessment fails
      false
    end

    private

    ##
    # Gathers all necessary context and constructs a detailed prompt for the AI.
    # @return [String] The prompt to be sent to the AI API.
    def build_prompt
      <<~PROMPT
        Analyze the following article to determine if it meets the specified quality criteria for a badge award.

        **Article Information:**
        ---
        Title: #{@article.title}
        Published: #{@article.published_at}
        Tags: #{@article.cached_tag_list}
        Reading Time: #{@article.reading_time} minutes
        ---

        **Article Content:**
        ---
        #{@article.body_markdown.first(5000)}
        ---

        **Quality Criteria:**
        #{@criteria}

        **Assessment Instructions:**
        - Evaluate whether the article meets the specified quality criteria
        - Consider the article's content, depth, relevance, and overall quality
        - The article should be substantive and meaningful
        - Exclude articles that are spam, low-effort, or do not meet the criteria

        Based on the quality criteria provided, does this article qualify for a badge award?

        Answer only with YES or NO.
      PROMPT
    end

    ##
    # Parses the AI's direct YES/NO response.
    # @param response [String] The text response from the AI.
    # @return [Boolean]
    def parse_response(response)
      # Check if the response contains "YES", ignoring case and leading/trailing whitespace.
      !response.nil? && response.strip.upcase.include?("YES")
    end
  end
end
