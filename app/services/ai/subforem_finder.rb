module Ai
  ##
  # Analyzes an article and finds the most appropriate subforem for it
  # based on content description specs of available subforems.
  class SubforemFinder
    # @param article [Article] The article to find an appropriate subforem for.
    def initialize(article)
      @ai_client = Ai::Base.new
      @article = article
    end

    ##
    # Finds the most appropriate subforem for the article.
    # Returns nil if no suitable subforem is found.
    #
    # @return [Integer, nil] The ID of the most appropriate subforem, or nil if none found.
    def find_appropriate_subforem
      available_subforems = get_available_subforems
      return if available_subforems.empty?

      # Try to find a good match first
      best_match = find_best_match(available_subforems)
      return best_match if best_match

      # If no good match, try the misc subforem as fallback
      misc_subforem = Subforem.misc_subforem
      return misc_subforem.id if misc_subforem

      nil
    end

    private

    attr_reader :ai_client, :article

    ##
    # Gets all available subforems that could potentially host this article.
    # Excludes the current subforem and non-discoverable subforems.
    #
    # @return [Array<Subforem>] Array of available subforems
    def get_available_subforems
      Subforem.where(discoverable: true)
        .where.not(id: article.subforem_id)
        .order(hotness_score: :desc)
    end

    ##
    # Uses AI to find the best matching subforem from available options.
    #
    # @param available_subforems [Array<Subforem>] Array of subforems to choose from
    # @return [Integer, nil] The ID of the best matching subforem, or nil if none suitable
    def find_best_match(available_subforems)
      return if available_subforems.empty?

      prompt = build_subforem_matching_prompt(available_subforems)

      begin
        response = ai_client.call(prompt)
        parse_subforem_response(response, available_subforems)
      rescue StandardError => e
        Rails.logger.error("AI subforem matching failed: #{e}")
        nil
      end
    end

    ##
    # Builds the prompt for AI to match the article with appropriate subforems.
    #
    # @param available_subforems [Array<Subforem>] Array of subforems to choose from
    # @return [String] The prompt to be sent to the AI
    def build_subforem_matching_prompt(available_subforems)
      article_context = build_article_context
      subforem_contexts = build_subforem_contexts(available_subforems)

      <<~PROMPT
        Analyze the following article and determine which subforem would be most appropriate for it.

        **Article to Analyze:**
        #{article_context}

        **Available Subforems:**
        #{subforem_contexts}

        **Instructions:**
        1. Read each subforem's content description spec carefully
        2. Determine which subforem's purpose and content guidelines best match this article
        3. Consider the article's topic, quality, and intended audience
        4. Only recommend a subforem if the article would be genuinely on-topic there
        5. If no subforem is a good fit, respond with "NONE"

        **Important Notes:**
        - The article was previously marked as offtopic for its current subforem
        - We want to find a subforem where this content would be genuinely appropriate
        - Quality of match is more important than quantity of options
        - Don't recommend a subforem just because it's available

        Respond with ONLY the subforem domain (e.g., "tech.example.com") or "NONE" if no good match exists.
      PROMPT
    end

    ##
    # Builds context about the article for the AI prompt.
    #
    # @return [String] Article context information
    def build_article_context
      <<~ARTICLE_CONTEXT
        Title: #{article.title}
        Tags: #{article.cached_tag_list}
        Body: #{article.body_markdown.truncate(3000)} #{'(Truncated)' if article.body_markdown.length > 3000}
        Published: #{article.published_at&.strftime('%B %d, %Y') || 'Not published'}
        Reading time: #{article.reading_time} minutes
        Word count: #{article.body_markdown.split.size} words
      ARTICLE_CONTEXT
    end

    ##
    # Builds context about available subforems for the AI prompt.
    #
    # @param available_subforems [Array<Subforem>] Array of subforems to describe
    # @return [String] Subforem context information
    def build_subforem_contexts(available_subforems)
      available_subforems.map.with_index(1) do |subforem, index|
        content_spec = Settings::RateLimit.internal_content_description_spec(subforem_id: subforem.id) ||
          Settings::Community.community_description(subforem_id: subforem.id)

        <<~SUBFOREM_CONTEXT
          Subforem #{index}:
          Domain: #{subforem.domain}
          Content Description Spec: #{content_spec.presence || 'No content description available'}
          ---
        SUBFOREM_CONTEXT
      end.join("\n")
    end

    ##
    # Parses the AI's response to extract the recommended subforem domain.
    #
    # @param response [String] The text response from the AI
    # @param available_subforems [Array<Subforem>] Array of available subforems
    # @return [Integer, nil] The ID of the recommended subforem, or nil if none recommended
    def parse_subforem_response(response, available_subforems)
      return unless response

      # Clean the response
      recommended_domain = response.strip.downcase

      # Check for "none" response
      return if recommended_domain.include?("none")

      # Find the subforem with the matching domain
      matching_subforem = available_subforems.find { |sf| sf.domain.downcase == recommended_domain }

      if matching_subforem
        Rails.logger.info("AI recommended subforem #{matching_subforem.domain} for article #{article.id}")
        matching_subforem.id
      else
        Rails.logger.warn("AI recommended unknown subforem domain '#{recommended_domain}' for article #{article.id}")
        nil
      end
    end
  end
end
