module Ai
  ##
  # Analyzes an article to determine its content moderation label.
  # This assesses articles based on quality, relevance, and spam indicators
  # to provide appropriate moderation labels for automated handling.
  class ContentModerationLabeler
    # @param article [Article] The article to be labeled.
    def initialize(article)
      @ai_client = Ai::Base.new
      @article = article
    end

    ##
    # Asks the AI to label the article and returns the label.
    #
    # @return [String] The moderation label for the article.
    def label
      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Content Moderation Labeling failed: #{e}")
      # Fallback to a safe default
      "no_moderation_label"
    end

    private

    ##
    # Builds a detailed prompt for the AI to assess article content.
    # @return [String] The prompt to be sent to the Gemini API.
    def build_prompt
      # Get the community description for context, specific to subforem if provided
      community_description = if @article.subforem_id
                                Settings::RateLimit.internal_content_description_spec(subforem_id: @article.subforem_id) ||
                                  Settings::Community.community_description(subforem_id: @article.subforem_id)
                              else
                                Settings::RateLimit.internal_content_description_spec ||
                                  Settings::Community.community_description
                              end

      # Gather user context
      user_context = build_user_context

      # Gather article context
      article_context = build_article_context

      <<~PROMPT
        Analyze the following article and assign it a content moderation label based on quality, relevance, and community standards.

        **Community Context:**
        #{community_description.presence || 'No specific community description provided.'}

        **User Context:**
        #{user_context}

        **Article Content:**
        #{article_context}

        **Assessment Criteria:**

        1. **Safety First**: Is the content harmful, exploitative, or inciting violence/hostility?
        2. **Content Quality**: Is the content well-written, informative, and valuable?
        3. **Community Relevance**: Does the content align with the community's purpose and interests?
        4. **Authenticity**: Does the content appear to be written by a real person with genuine insights?
        5. **Spam Indicators**: Are there signs of promotional content, low-effort posts, or automated generation?
        6. **Community Building**: Does the content foster discussion and community engagement?

        **Label Categories:**

        **Safety Labels (Highest Priority):**
        - `clear_and_obvious_harmful`: Content involving human trafficking, doxing, calls for violence, or other clearly exploitative/harmful content
        - `likely_harmful`: Content that appears to involve harmful activities but not definitively so
        - `clear_and_obvious_inciting`: Over-the-top aggression, direct rage, or content clearly designed to incite violence or extreme hostility
        - `likely_inciting`: Content that appears to be inciting but not definitively so

        **Spam Labels:**
        - `clear_and_obvious_spam`: Obvious promotional content, automated posts, or malicious content
        - `likely_spam`: Content with strong spam indicators but not definitively spam

        **Quality Labels:**
        - `clear_and_obvious_low_quality`: Poorly written, uninformative, or clearly low-effort content
        - `likely_low_quality`: Content that appears low quality but not definitively so

        **Relevance Labels:**
        - `ok_but_offtopic_for_subforem`: Decent content but not relevant to this community
        - `okay_and_on_topic`: Acceptable content that fits the community
        - `very_good_but_offtopic_for_subforem`: High-quality content but not relevant to this community
        - `very_good_and_on_topic`: High-quality content that fits the community well
        - `great_and_on_topic`: Exceptional content that perfectly fits the community
        - `great_but_off_topic_for_subforem`: Exceptional content but not relevant to this community

        **Guidelines for Labeling:**

        **Safety Indicators (Check First):**
        - Content involving human trafficking, exploitation, or illegal activities
        - Doxing (sharing private personal information without consent)
        - Direct calls for violence or harm against individuals/groups
        - Over-the-top aggression, rage, or hostility that could incite violence
        - Content designed to provoke extreme emotional responses or conflict

        **Spam Indicators:**
        - Excessive promotional language or links
        - Generic, impersonal content that could be AI-generated
        - Content that doesn't engage with the community
        - Suspicious patterns or automated behavior

        **Quality Indicators:**
        - Well-structured, thoughtful content
        - Personal experiences and genuine insights
        - Proper formatting and readability
        - Evidence of research or expertise

        **Relevance Indicators:**
        - Content that addresses community interests
        - Topics that align with the community's purpose
        - Content that would be valuable to community members

        Respond with ONLY the label name (e.g., "okay_and_on_topic"):

      PROMPT
    end

    ##
    # Builds context about the user who wrote the article.
    # @return [String] User context information.
    def build_user_context
      user = @article.user
      <<~USER_CONTEXT
        Author: #{user.name} (@#{user.username})
        Member since: #{user.created_at.strftime('%B %Y')}
        Badge achievements: #{user.badge_achievements_count}
        Articles published: #{user.articles.published.count}
        Comments made: #{user.comments.count}
        Profile summary: #{user.profile&.summary || 'No summary provided'}
      USER_CONTEXT
    end

    ##
    # Builds context about the article content.
    # @return [String] Article context information.
    def build_article_context
      <<~ARTICLE_CONTEXT
        Title: #{@article.title}
        Tags: #{@article.cached_tag_list}
        Body: #{@article.body_markdown.truncate(5000)} #{'(Truncated)' if @article.body_markdown.length > 5000}
        Published: #{@article.published_at&.strftime('%B %d, %Y') || 'Not published'}
        Reading time: #{@article.reading_time} minutes
        Word count: #{@article.body_markdown.split.size} words
      ARTICLE_CONTEXT
    end

    ##
    # Parses the AI's response to extract the label.
    # @param response [String] The text response from the AI.
    # @return [String] The moderation label.
    def parse_response(response)
      return "no_moderation_label" unless response

      # Clean and normalize the response
      label = response.strip.downcase.gsub(/[^a-z_]/, '')

      # Validate the label is one of the expected values
      valid_labels = %w[
        no_moderation_label
        clear_and_obvious_harmful
        likely_harmful
        clear_and_obvious_inciting
        likely_inciting
        clear_and_obvious_spam
        likely_spam
        clear_and_obvious_low_quality
        likely_low_quality
        ok_but_offtopic_for_subforem
        okay_and_on_topic
        very_good_but_offtopic_for_subforem
        very_good_and_on_topic
        great_and_on_topic
        great_but_off_topic_for_subforem
      ]

      valid_labels.include?(label) ? label : "no_moderation_label"
    end
  end
end
