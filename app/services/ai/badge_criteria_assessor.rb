module Ai
  ##
  # Analyzes an article to determine if it meets quality criteria for badge awards.
  # This class uses AI to assess whether an article meets specific quality standards
  # based on custom criteria provided.
  #
  # When the :badge_criteria function is set to Jev (see Ai::FunctionConfig), the admin's
  # criteria are passed as structured data to a TypeSafe Noul, alongside separate checks
  # for the baseline exclusions (spam, low effort).
  class BadgeCriteriaAssessor
    include Ai::TypeSafe::Questions

    VERSION = "1.1".freeze
    FUNCTION_KEY = :badge_criteria

    # Jev policy thresholds. Awarding a badge wrongly is visible and hard to undo, so require
    # a confident yes on the criteria and no likely exclusion.
    QUALIFIES = 0.7
    DISQUALIFIES = 0.5

    # @param article [Article] The article object to be assessed.
    # @param criteria [String] The quality criteria to check against.
    def initialize(article, criteria:)
      @article = article
      @criteria = criteria
      @selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      return if @selection.jev?

      @ai_client = Ai::Base.new(model: @selection.gemini_model, wrapper: self, affected_content: article,
                                affected_user: article.user)
    end

    ##
    # Asks the AI if the article meets the quality criteria.
    #
    # @return [Boolean] true if the article qualifies, false otherwise.
    def qualifies?
      return qualifies_via_jev? if @selection.jev?

      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Badge Criteria Assessment failed: #{e}")
      # Fallback to false if AI assessment fails
      false
    end

    private

    # --- Jev (TypeSafe System One) ---

    def qualifies_via_jev?
      client = Ai::TypeSafe::Client.new(model: @selection.model, wrapper: self, affected_content: @article,
                                        affected_user: @article.user)
      result = client.evaluate(state: jev_state, questions: jev_questions)

      result.noul(:meets_criteria) >= QUALIFIES &&
        result.noul(:spam_or_low_effort) < DISQUALIFIES
    end

    def jev_state
      {
        article: {
          title: @article.title,
          tags: @article.cached_tag_list,
          reading_time_minutes: @article.reading_time,
          body: @article.body_markdown.to_s.first(5000)
        }
      }
    end

    def jev_questions
      {
        # The criteria are admin-authored, so they go in as data the question refers to.
        meets_criteria: noul(
          {
            badge_criteria: @criteria.to_s,
            question: "Does `article` meet every requirement in `badge_criteria`?"
          },
        ),
        spam_or_low_effort: noul(
          "Is `article` spam or a low-effort post without substantive content?",
        )
      }
    end

    # --- Gemini ---

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
