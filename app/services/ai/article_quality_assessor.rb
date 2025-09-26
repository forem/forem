module Ai
  ##
  # Analyzes a set of articles to determine which is the highest quality and which is the lowest quality.
  # This assesses articles against one-another and using the content spec from configuration.
  # It is ultimately used only for *nudging* purposes and should not be used for major actions.
  # This class uses AI to assess articles based on authenticity, community value, and non-promotional content.
  class ArticleQualityAssessor
    # @param articles [Array<Article>] The articles to be assessed.
    # @param subforem_id [Integer, nil] The subforem ID for context-specific assessment.
    def initialize(articles, subforem_id: nil)
      @ai_client = Ai::Base.new
      @articles = articles
      @subforem_id = subforem_id
    end

    ##
    # Asks the AI to identify the best and worst articles from the set.
    #
    # @return [Hash] A hash with :best and :worst keys containing the article objects.
    def assess
      return { best: nil, worst: nil } if @articles.empty?
      return { best: @articles.first, worst: @articles.first } if @articles.length == 1

      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Article Quality Assessment failed: #{e}")
      # Fallback to simple score-based selection
      fallback_assessment
    end

    private

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
        <<~ARTICLE
          Article #{index}:
          Tags: #{article.cached_tag_list}
          Title: #{article.title}
          Body: #{article.body_markdown.truncate(10_000)} #{'(Truncated)' if article.body_markdown.length > 10_000}
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
