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
    CLEAR = 0.9
    LIKELY = 0.6
    SUPPORTING = 0.5

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
    rescue Ai::Base::ProhibitedContentError
      raise
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
      profile_state = {
        name: @user.name,
        username: @user.username,
        summary: @user.profile&.summary,
        website_url: @user.profile&.website_url,
        location: @user.profile&.location
      }
      profile_state[:fields] = custom_profile_fields if custom_profile_fields.any?

      state = {
        community: { description: default_community_description.presence || "No community description provided." },
        profile: profile_state
      }
      state[:recent_articles] = recent_articles_context if recent_articles_context.any?
      state
    end

    def jev_questions
      questions = {
        keyword_stuffed_identity: noul(
          "Is `profile.name` or `profile.username` blatant, egregious commercial spam (such as black-hat SEO " \
          "keyword stuffing, gambling/casino ads, adult/escort services, fake customer-support phone numbers, " \
          "or illegal/scam services) rather than a person, handle, brand, or organization?",
          yes: {
            examples: [
              "Best Cheap SEO Services Delhi",
              "buy-backlinks-casino-slots-2024",
              "Call +1-800-555-0199 Airlines Support",
            ]
          },
          no: {
            examples: ["Jane Doe", "Acme Cloud", "jdoe_dev", "thebitforge", "Alex Rivera - Full Stack Developer"],
            includes: "Any real name, pseudonym, developer handle, startup/company/project name, or name that " \
                      "includes a job title, role, or tech stack."
          },
        ),
        promotional_profile: noul(
          {
            question: "Are `profile.summary` and `profile.website_url` blatant, egregious spam (such as SEO " \
                      "link-selling, casinos/gambling, adult/escort ads, crypto/financial scams, pirated " \
                      "downloads, or fake support numbers) rather than a legitimate person, project, or business?"
          },
          yes: {
            examples: [
              "Buy high DR backlinks and cheap guest posts at our casino SEO agency.",
              "24/7 Escort girls in Dubai - click website for WhatsApp.",
            ]
          },
          no: {
            includes: "Any legitimate person, developer, freelancer, startup, agency, company, or organization " \
                      "describing itself, its products, its tech stack, or its interests—even if self-promotional, " \
                      "commercial, or off-topic—with a link to its own site, portfolio, or social profile."
          },
        ),
        plausible_profile: noul(
          "Could `profile` plausibly belong to a real person, developer, student, hobbyist, or legitimate " \
          "company/organization (even if self-promotional, minimal, or off-topic), rather than an egregious " \
          "spam bot?",
          yes: "A real person, developer, freelancer, founder, student, or normal business/organization, " \
               "including profiles that promote their own project, product, service, or website.",
          no: "An unmistakably automated or abusive spam profile (e.g., SEO backlink sellers, casino/gambling " \
              "ads, adult/escort services, scams, pirated streaming/downloads, or fake support phone numbers).",
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
          "Are the posts in `recent_articles` blatant spam or promotional abuse rather than good-faith contributions?",
        )
      end
      questions
    end

    # Safety labels take precedence over spam, matching the label priority used for articles.
    # Profile-only spam signals are suppressed when the profile plausibly belongs to a real person or organization.
    def label_from_jev(result)
      profile_spam = if result.noul(:plausible_profile) >= SUPPORTING
                       0.0
                     else
                       [result.noul(:keyword_stuffed_identity), result.noul(:promotional_profile)].max
                     end
      spam = [profile_spam]
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

    def custom_profile_fields
      @custom_profile_fields ||= begin
        data = @user.profile&.data
        if data.is_a?(Hash)
          data.except("social_image").each_with_object({}) do |(key, value), fields|
            cleaned = value.to_s.strip
            fields[key.to_s] = cleaned if cleaned.present?
          end
        else
          {}
        end
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

      if custom_profile_fields.any?
        custom_lines = custom_profile_fields.map { |key, value| "#{key.humanize}: #{value}" }.join("\n")
        profile_context = "#{profile_context}#{custom_lines}\n"
      end

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
        - We are looking ONLY for *blatant, egregious spam bots or severe abuse*. Be extremely conservative: if there is any chance the profile belongs to a real person, developer, student, creator, or legitimate business/organization, choose `no_moderation_label`.
        - Use `clear_and_obvious_spam` ONLY for unmistakable, egregious commercial spam (such as black-hat SEO/backlink sellers, online casinos/gambling, adult/escort services, crypto recovery or loan-shark scams, pirated downloads/streaming, or fake customer-support phone numbers).
        - Do NOT use `clear_and_obvious_spam` for self-promotion, freelancers, agencies, startups, SaaS products, personal websites, portfolios, or off-topic businesses.
        - Developer handles, pseudonyms, studio/project names, and bios listing tech stacks, roles, or interests are normal and must be labeled `no_moderation_label`.
        - Use `clear_and_obvious_harmful` ONLY for severe, unmistakable abuse, exploitation, trafficking, or doxing.
        - Use `clear_and_obvious_inciting` ONLY for content that explicitly incites violence or extreme hostility.

        Return only the label.
      PROMPT
    end

    def parse_response(response)
      return "no_moderation_label" if response.blank?

      text = response.to_s
      cleaned = text.strip.gsub(/\A[`"'\s]+|[`"'\s.]+\z/, "")
      return cleaned if LABELS.include?(cleaned)

      lines = text.lines.map { |line| line.strip.gsub(/\A[`"'\s*-]+|[`"'\s.]+\z/, "") }.compact_blank
      exact_line = lines.reverse.detect { |line| LABELS.include?(line) }
      return exact_line if exact_line

      non_negated_matches = text.enum_for(:scan, /\b(#{Regexp.union(LABELS)})\b/).filter_map do
        label = Regexp.last_match(1)
        prefix = text[0...Regexp.last_match.begin(0)]
        negated = prefix.match?(
          /\b(?:not|no|isn't|isnt|never|without|rather\s+than)\s+(?:[`"']|\b(?:a|an|the|label)\b\s*)*\z/i,
        )
        label unless negated
      end

      non_negated_matches.last || "no_moderation_label"
    end
  end
end
