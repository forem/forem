module Ai
  # Evaluates whether an article is appropriate contextually for a given Concept using Gemini AI.
  #
  # When the :concept_article_relevance function is set to Jev (see Ai::FunctionConfig), a
  # TypeSafe Noul judges the fit, and uncertain answers come back as nil so they do not move
  # the concept's threshold either way (see Concepts::ThresholdEvaluator).
  class ConceptArticleEvaluator
    include Ai::TypeSafe::Questions

    VERSION = "1.1".freeze
    FUNCTION_KEY = :concept_article_relevance

    # Jev policy: confident yes / confident no; the band in between abstains.
    FITS = 0.65
    DOES_NOT_FIT = 0.35

    # @param concept [Concept] The concept to evaluate against.
    # @param article [Article] The article to evaluate.
    def initialize(concept, article)
      @concept = concept
      @article = article
      @selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      return if @selection.jev?

      @ai_client = Ai::Base.new(model: @selection.gemini_model, wrapper: self, affected_user: article.user,
                                affected_content: article)
    end

    # Asks the AI if the article is appropriate/relevant for the concept.
    # @return [Boolean, nil] true if appropriate, false if inappropriate, nil if AI evaluation fails.
    def appropriate?
      return appropriateness_via_jev if @selection.jev?

      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Ai::ConceptArticleEvaluator Concept #{@concept.id} Article #{@article.id}: #{e.message}")
      nil
    end

    private

    # --- Jev (TypeSafe System One) ---

    def appropriateness_via_jev
      client = Ai::TypeSafe::Client.new(model: @selection.model, wrapper: self, affected_user: @article.user,
                                        affected_content: @article)
      state = {
        concept: { name: @concept.name, description: @concept.description.presence || "No description provided." },
        article: { title: @article.title, body: @article.body_markdown.to_s.truncate(2000) }
      }
      questions = {
        fits_concept: noul(
          "Do the primary topics, technologies, or discussion points of `article` fall under `concept`?",
          no: { includes: "An article that only mentions `concept.name` in passing while being about something else." },
        )
      }

      fit = client.evaluate(state: state, questions: questions).noul(:fits_concept)
      return true if fit >= FITS
      return false if fit <= DOES_NOT_FIT

      nil
    end

    # --- Gemini ---

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
