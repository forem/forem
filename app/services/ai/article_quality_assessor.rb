module Ai
  ##
  # Analyzes a set of articles to determine which is the highest quality and which is the lowest quality.
  # This assesses articles against one-another and using the content spec from configuration.
  # It is ultimately used only for *nudging* purposes and should not be used for major actions.
  # This class uses AI to assess articles based on authenticity, community value, and non-promotional content.
  #
  # When the :article_quality_ranking function is set to Jev (see Ai::FunctionConfig), each
  # article is scored on its own along independent dimensions (composite scoring), and code
  # ranks the resulting comparable scores to pick best and worst. Scoring articles separately
  # keeps each request's state small and focused, instead of asking one question over a large
  # state holding every article.
  class ArticleQualityAssessor
    include Ai::TypeSafe::Questions

    VERSION = "1.1".freeze
    FUNCTION_KEY = :article_quality_ranking

    # Weights for the composite quality score. They sum to 1.
    QUALITY_WEIGHTS = {
      human_connection: 0.3,
      community_value: 0.3,
      engagement: 0.2,
      authenticity: 0.2
    }.freeze
    # A clear red flag subtracts this much from the 0-1 composite.
    RED_FLAG_PENALTY = 0.5
    CLEAR = 0.85

    # @param articles [Array<Article>] The articles to be assessed.
    # @param subforem_id [Integer, nil] The subforem ID for context-specific assessment.
    def initialize(articles, subforem_id: nil)
      @articles = articles
      @subforem_id = subforem_id
      @selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      return if @selection.jev?

      @ai_client = Ai::Base.new(model: @selection.gemini_model, wrapper: self)
    end

    ##
    # Asks the AI to identify the best and worst articles from the set.
    #
    # @return [Hash] A hash with :best and :worst keys containing the article objects.
    def assess
      return { best: nil, worst: nil } if @articles.empty?
      return { best: @articles.first, worst: @articles.first } if @articles.length == 1
      return assess_via_jev if @selection.jev?

      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Article Quality Assessment failed: #{e}")
      # Fallback to simple score-based selection
      fallback_assessment
    end

    private

    # --- Jev (TypeSafe System One) ---

    def assess_via_jev
      scored = @articles.filter_map do |article|
        result = jev_client.evaluate(state: jev_state(article), questions: jev_questions)
        { article: article, quality: composite_quality(result), red_flag: red_flag?(result) }
      rescue StandardError => e
        Rails.logger.error("Article Quality Assessment via Jev failed for article #{article.id}: #{e}")
        nil
      end
      return fallback_assessment if scored.length < 2

      best = scored.max_by { |entry| entry[:quality] }
      # Trusted authors and publishers are only picked as worst on a clear red flag.
      worst_pool = scored.reject do |entry|
        entry.equal?(best) || (trusted_author?(entry[:article]) && !entry[:red_flag])
      end
      worst = worst_pool.min_by { |entry| entry[:quality] }

      { best: best[:article], worst: worst&.dig(:article) }
    end

    def jev_client
      @jev_client ||= Ai::TypeSafe::Client.new(model: @selection.model, wrapper: self)
    end

    def jev_state(article)
      state = {
        community: { description: community_description.presence || "No specific community description provided." },
        article: {
          title: article.title,
          tags: article.cached_tag_list,
          body: article.body_markdown.to_s.truncate(6_000)
        }
      }
      top_comments = article.comments.order(score: :desc).limit(3).pluck(:body_markdown)
        .map { |content| content.to_s.truncate(750) }
      state[:article][:top_comments] = top_comments if top_comments.any?
      state
    end

    def jev_questions
      @jev_questions ||= {
        human_connection: score(
          "How much does `article` share the author's real experiences, struggles, or insights?",
          [
            "None; impersonal and could be written by anyone.",
            "A few personal touches.",
            "Clearly grounded in the author's own experience.",
            "Deeply personal, with a distinctive perspective and voice.",
          ],
        ),
        community_value: score(
          "How meaningfully does `article` contribute to the purpose in `community.description`?",
          [
            "Off-topic or irrelevant to this community.",
            "Related, but adds little for members.",
            "A useful contribution for members.",
            "A standout contribution members will value and reference.",
          ],
        ),
        engagement: score(
          "How much does `article` invite discussion, help others, or respond to the community?",
          [
            "Broadcast only; nothing for readers to engage with.",
            "Some value to readers, little invitation to engage.",
            "Helps readers or invites thoughtful replies.",
            "Actively builds conversation, asks the community, or answers real needs.",
          ],
        ),
        authenticity: score(
          "How clearly does `article` read as written by a real person rather than generic generated text?",
          [
            "Generic, formulaic text that reads as machine-generated.",
            "Mostly generic, with little individual voice.",
            "Reads as a real person's writing.",
            "Unmistakably a real person's voice and perspective.",
          ],
        ),
        dishonest_promotion: noul(
          "Is `article` marketing content disguised as a community post?",
          no: { includes: "A straightforward, honest launch announcement or project share." },
        ),
        low_effort: noul(
          "Is `article` a low-effort post with little genuine content?",
        )
      }
    end

    def composite_quality(result)
      quality = QUALITY_WEIGHTS.sum { |dimension, weight| weight * result.score(dimension).normalized }
      quality -= RED_FLAG_PENALTY if red_flag?(result)
      quality
    end

    def red_flag?(result)
      result.noul(:dishonest_promotion) >= CLEAR || result.noul(:low_effort) >= CLEAR
    end

    def trusted_author?(article)
      author_trustworthiness_profile(article).present?
    end

    def community_description
      @community_description ||= if @subforem_id
                                   Settings::RateLimit.internal_content_description_spec(subforem_id: @subforem_id) ||
                                     Settings::Community.community_description(subforem_id: @subforem_id)
                                 else
                                   Settings::RateLimit.internal_content_description_spec ||
                                     Settings::Community.community_description
                                 end
    end

    # --- Gemini ---

    ##
    # Builds a detailed prompt for the AI to assess article quality.
    # @return [String] The prompt to be sent to the Gemini API.
    def build_prompt
      # Get the community description for context, specific to subforem if provided
      community_description = if @subforem_id
                                Settings::RateLimit.internal_content_description_spec(subforem_id: @subforem_id) ||
                                  Settings::Community.community_description(subforem_id: @subforem_id)
                              else
                                Settings::RateLimit.internal_content_description_spec ||
                                  Settings::Community.community_description
                              end

      articles_text = @articles.map.with_index(1) do |article, index|
        bg_context = author_trustworthiness_profile(article)
        <<~ARTICLE
          Article #{index}:
          Tags: #{article.cached_tag_list}
          Title: #{article.title}
          #{"#{bg_context}\n" if bg_context}Body: #{article.body_markdown.truncate(10_000)} #{'(Truncated)' if article.body_markdown.length > 10_000}
          #{"Top Comments: #{article.comments.order(score: :desc).limit(3).pluck(:body_markdown).map { |content| content.truncate(750) }.join("\n")}" if article.comments.any?}
          ---
        ARTICLE
      end.join("\n")

      <<~PROMPT
        Analyze the following #{@articles.length} articles and identify which one is the HIGHEST QUALITY and which one is the LOWEST QUALITY.

        Your assessment should focus on AUTHENTIC COMMUNITY-ORIENTED CONTENT that demonstrates genuine human connection and value that cannot be easily simulated by AI.

        **Community Context:**
        #{community_description.presence || 'No specific community description provided.'}

        **Assessment Criteria:**

        1. **Authentic Human Connection**: Does the author communicate personally, sharing real experiences, struggles, or insights that show genuine human perspective?

        2. **Community Relevance**: Does the content meaningfully contribute to the community's purpose and interests, beyond just being technically correct?

        3. **Genuine Engagement**: Does the content invite thoughtful discussion, help others, or address real community needs?

        4. **Non-AI-Generated Authenticity**: Does the content show signs of being written by a real person with unique perspective, rather than generic AI-generated content?

        5. **Community Building**: Does it foster connections, share knowledge in a personal way, or help build the community?

        **HIGH QUALITY indicators (authentic community content):**
        - Personal stories and experiences that relate to the community
        - Genuine questions or discussions that invite community input
        - Likely to create or continue to building genuine discussion threads
        - Reactive to other posts directly within the community, or intent on sharing via embeds, etc.
        - Sharing of real struggles, failures, or learning moments
        - Content that helps others in a personal, relatable way
        - Authentic enthusiasm or passion for the topic
        - Content that shows the author's unique perspective and voice
        - Community-focused questions or discussions
        - Sharing of personal projects or experiments

        **LOW QUALITY indicators (easily AI-generated or non-community-focused):**
        - Generic, impersonal content that could be written by anyone
        - Pure promotional or marketing content
          - Promotion is okay if it's straightforward and honest. I.e. the post itself is an explicient launch anncounement etc. This should be considered quality authentic community content.
        - Content that doesn't engage with the community
        - Overly formal or academic content without personal touch
        - Content that feels like it was generated by AI
        - Off-topic or irrelevant content
        - Low-effort posts without genuine engagement
        - Poor formatting or structure

        Here are the articles to assess:

        #{articles_text}

        Based on your analysis, respond with ONLY two numbers separated by a comma:
        - First number: The article number (1-#{@articles.length}) that is the HIGHEST QUALITY (most authentically community-oriented)
        - Second number: The article number (1-#{@articles.length}) that is the LOWEST QUALITY (least authentically community-oriented)

        Example response: "3,7" (meaning Article 3 is highest quality, Article 7 is lowest quality)

        Respond with only the two numbers separated by a comma:
      PROMPT
    end

    def author_trustworthiness_profile(article)
      return nil if article.user.nil?

      trust_factors = []
      trust_factors << "published by a verified organization" if article.organization&.verified?
      trust_factors << "written by a DEV++ subscriber" if article.user.base_subscriber?
      trust_factors << "written by a trusted member of the community" if article.user.trusted?

      score = article.user.score.to_i
      if score > 500
        trust_factors << "written by an exceptionally reputable user (user score: #{score})"
      elsif score > 100
        trust_factors << "written by an established user with a solid reputation (user score: #{score})"
      end

      return nil if trust_factors.empty?

      "Author/Publisher Background: This article is #{trust_factors.to_sentence}. Given these credentials, err on the side of treating this article as good quality unless there is clear evidence of low-effort spam."
    end

    ##
    # Parses the AI's response to extract the best and worst article indices.
    # @param response [String] The text response from the AI.
    # @return [Hash] Hash with :best and :worst article objects.
    def parse_response(response)
      return fallback_assessment unless response

      # Extract numbers from response (e.g., "3,7" or "Article 3 is best, Article 7 is worst")
      numbers = response.scan(/\d+/).map(&:to_i)

      return fallback_assessment unless numbers.length >= 2

      best_index = numbers[0] - 1  # Convert to 0-based index
      worst_index = numbers[1] - 1 # Convert to 0-based index

      # Validate indices
      return fallback_assessment unless best_index.between?(0, @articles.length - 1) &&
        worst_index.between?(0, @articles.length - 1)

      {
        best: @articles[best_index],
        worst: @articles[worst_index]
      }
    end

    def fallback_assessment
      {
        best: nil,
        worst: nil
      }
    end
  end
end
