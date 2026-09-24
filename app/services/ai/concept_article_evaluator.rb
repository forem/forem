module Ai
  # Evaluates whether an article is appropriate contextually for a given Concept using Gemini AI.
  class ConceptArticleEvaluator
    VERSION = "1.0".freeze

    # @param concept [Concept] The concept to evaluate against.
    # @param article [Article] The article to evaluate.
    def initialize(concept, article)
      @concept = concept
      @article = article
      @ai_client = Ai::Base.new(wrapper: self, affected_user: article.user, affected_content: article)
    end

    # Asks the AI if the article is appropriate/relevant for the concept.
    # @return [Boolean, nil] true if appropriate, false if inappropriate, nil if AI evaluation fails.
    def appropriate?
      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Ai::ConceptArticleEvaluator Concept #{@concept.id} Article #{@article.id}: #{e.message}")
      nil
    end

    private

    def build_prompt
      body_snippet = @article.body_markdown.to_s.truncate(2000)

      <<~PROMPT
        You are an expert content evaluator for a developer community platform.
        Your task is to determine whether the provided ARTICLE is contextually relevant and appropriate for the specified CONCEPT.

        CONCEPT NAME: #{@concept.name}
        CONCEPT DESCRIPTION: #{@concept.description.presence || 'No description provided.'}

        ARTICLE TO EVALUATE:
        Title: #{@article.title}
        Body Snippet: #{body_snippet}

        Evaluation Rules:
        - Answer YES if the article's primary topics, technologies, or discussion points fit logically under the CONCEPT.
        - Answer NO if the article is off-topic, unrelated, or caught by error for this CONCEPT.

        Your response must be a single word: YES or NO.
      PROMPT
    end

    def parse_response(response)
      return if response.blank?

      cleaned = response.strip.upcase
      if cleaned.include?("YES")
        true
      elsif cleaned.include?("NO")
        false
      end
    end
  end
end
