module Ai
  ##
  # Analyzes a user's profile and recent articles to determine a moderation label.
  # This is intended for detecting clear and obvious spam or abuse.
  #
  # When the :profile_moderation function is set to Jev (see Ai::FunctionConfig), the label
  # is composed in #label_from_jev from narrow TypeSafe Noul questions.
  class ProfileModerationLabeler
    include Ai::TypeSafe::Questions

    VERSION = "1.1".freeze
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

    FUNCTION_KEY = :profile_moderation
    # Jev policy thresholds. Only clear_* labels trigger action in Spam::Handler.
    CLEAR = 0.85
    LIKELY = 0.6

    # @param user [User] The user whose profile we are labeling.
    # @param ai_client [Ai::Base, nil] Optional Gemini client (forces the Gemini path).
    def initialize(user, ai_client: nil)
      @user = user
      @selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      @use_jev = ai_client.nil? && @selection.jev?
      return if @use_jev

      @ai_client = ai_client || Ai::Base.new(model: @selection.gemini_model, wrapper: self, affected_user: user)
    end

    ##
    # Asks the AI to label the profile and returns the label.
    #
    # @return [String] The moderation label for the profile.
    def label
      return label_via_jev if @use_jev

      response = @ai_client.call(build_prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Profile Moderation Labeling failed: #{e}")
      "no_moderation_label"
    end

    private

    # --- Jev (TypeSafe System One) ---

    def label_via_jev
      client = Ai::TypeSafe::Client.new(model: @selection.model, wrapper: self, affected_user: @user)
      label_from_jev(client.evaluate(state: jev_state, questions: jev_questions))
    end

    def jev_state
      state = {
        community: { description: default_community_description.presence || "No community description provided." },
        profile: {
          name: @user.name,
          username: @user.username,
          summary: @user.profile&.summary,
          website_url: @user.profile&.website_url,
          location: @user.profile&.location
        }
      }
      state[:recent_articles] = recent_articles_context if recent_articles_context.any?
      state
    end

    def jev_questions
      questions = {
        keyword_stuffed_identity: noul(
          "Is `profile.name` or `profile.username` a keyword-stuffed or promotional phrase rather than the name " \
          "of a person or organization?",
          yes: { examples: ["Best Cheap SEO Services Delhi", "buy-followers-fast-2024"] },
          no: { examples: ["Jane Doe", "Acme Cloud", "jdoe_dev"] },
        ),
        promotional_profile: noul(
          {
            question: "Do `profile.summary` and `profile.website_url` exist mainly to advertise or drive search " \
                      "traffic to an unrelated business?"
          },
          no: {
            includes: "A legitimate person, company, or organization describing itself, even with a link " \
                      "to its own site."
          },
        ),
        harmful: noul(
          "Does the profile or its recent articles show exploitation, trafficking, doxing, or other clearly " \
          "harmful activity?",
        ),
        inciting: noul(
          "Does the profile or its recent articles call for violence or incite extreme hostility toward people?",
        )
      }
      if recent_articles_context.any?
        questions[:spam_articles] = noul(
          "Are the posts in `recent_articles` spam or promotional abuse rather than good-faith contributions?",
        )
      end
      questions
    end

    # Safety labels take precedence over spam, matching the label priority used for articles.
    def label_from_jev(result)
      spam = [result.noul(:keyword_stuffed_identity), result.noul(:promotional_profile)]
      spam << result.noul(:spam_articles) if result.key?(:spam_articles)
      signals = {
        "harmful" => result.noul(:harmful),
        "inciting" => result.noul(:inciting),
        "spam" => spam.max
      }

      clear = signals.detect { |_kind, probability| probability >= CLEAR }
      return "clear_and_obvious_#{clear.first}" if clear

      likely = signals.detect { |_kind, probability| probability >= LIKELY }
      return "likely_#{likely.first}" if likely

      "no_moderation_label"
    end

    def default_community_description
      default_subforem_id = Subforem.cached_default_id
      Settings::RateLimit.internal_content_description_spec(subforem_id: default_subforem_id) ||
        Settings::Community.community_description(subforem_id: default_subforem_id)
    end

    def recent_articles_context
      @recent_articles_context ||= @user.articles.published.order(published_at: :desc).limit(2).map do |article|
        { title: article.title, body: article.body_markdown.to_s.truncate(1_200) }
      end
    end

    # --- Gemini ---

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
                               Body#{' (truncated)' if article.body_markdown.to_s.size > 1_200}: #{body}
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
        #{LABELS.join(', ')}

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
