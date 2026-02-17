module Ai
  ##
  # Analyzes a user's profile and recent articles to determine a moderation label.
  # This is intended for detecting clear and obvious spam or abuse.
  class ProfileModerationLabeler
    LABELS = %w[
      no_moderation_label
      clear_and_obvious_spam
      likely_spam
      clear_and_obvious_low_quality
      likely_low_quality
      clear_and_obvious_harmful
      likely_harmful
      clear_and_obvious_inciting
      likely_inciting
      ok_but_offtopic_for_subforem
      okay_and_on_topic
      very_good_but_offtopic_for_subforem
      very_good_and_on_topic
      great_and_on_topic
      great_but_off_topic_for_subforem
    ].freeze

    # @param user [User] The user whose profile we are labeling.
    def initialize(user, ai_client: Ai::Base.new)
      @ai_client = ai_client
      @user = user
    end

    ##
    # Asks the AI to label the profile and returns the label.
    #
    # @return [String] The moderation label for the profile.
    def label
      response = @ai_client.call(build_prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Profile Moderation Labeling failed: #{e}")
      "no_moderation_label"
    end

    private

    def build_prompt
      # Use default subforem instructions/community description for context
      default_subforem_id = Subforem.cached_default_id
      community_description = Settings::RateLimit.internal_content_description_spec(subforem_id: default_subforem_id) ||
        Settings::Community.community_description(subforem_id: default_subforem_id)

      recent_articles = @user.articles.published.order(published_at: :desc).limit(2)
      articles_context = if recent_articles.any?
                           recent_articles.map.with_index(1) do |article, index|
                             body = article.body_markdown.to_s.first(1_200)
                             <<~ARTICLE
                               Article #{index}:
                               Title: #{article.title}
                               Body#{ " (truncated)" if article.body_markdown.to_s.size > 1_200 }: #{body}
                             ARTICLE
                           end.join("\n")
                         else
                           "No published articles available."
                         end

      profile_context = <<~PROFILE
        Name: #{@user.name}
        Username: #{@user.username}
        Summary: #{@user.profile&.summary}
        Website URL: #{@user.profile&.website_url}
        Location: #{@user.profile&.location}
        Published articles count: #{@user.articles.published.count}
        Published comments count: #{@user.comments.where(deleted: false).count}
      PROFILE

      <<~PROMPT
        Analyze the following user profile and recent content. Return one moderation label from the list below and nothing else.

        **Community Context (Default Subforem):**
        #{community_description.presence || 'No community description provided.'}

        **Profile Context:**
        #{profile_context}

        **Recent Published Articles (if any):**
        #{articles_context}

        **Label Categories (choose one):**
        #{LABELS.join(", ")}

        **Guidelines:**
        - We are looking for *clear and obvious spam or abuse* only.
        - If the profile and recent content appear legitimate or borderline, choose `no_moderation_label`.
        - Use `clear_and_obvious_spam` for unmistakable spam or promotional abuse.
        - Treat clear SEO abuse as spam (keyword-stuffed names, off-topic profile names, or spammy URLs).
        - Legitimate organizations and businesses belong here, but SEO spam does not.
        - Use `clear_and_obvious_harmful` for clear abuse, exploitation, or harmful activity.
        - Use `clear_and_obvious_inciting` for content that clearly incites violence or extreme hostility.

        Return only the label.
      PROMPT
    end

    def parse_response(response)
      return "no_moderation_label" if response.blank?

      LABELS.find { |label| response.include?(label) } || "no_moderation_label"
    end
  end
end
