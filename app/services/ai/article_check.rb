module Ai
  ##
  # Analyzes an article to determine if it is likely spam.
  #
  # This class gathers context from the article, its author's publication
  # history, and the community it's posted in to create a detailed
  # prompt for the AI.
  #
  # When the :article_spam_check function is set to Jev (see Ai::FunctionConfig), the
  # holistic YES/NO prompt is replaced by a battery of narrow TypeSafe Noul questions whose
  # probabilities are combined by the explicit policy in #spam_from_jev?.
  class ArticleCheck
    include Ai::CommunityContext
    include Ai::TypeSafe::Questions

    VERSION = "1.2".freeze
    FUNCTION_KEY = :article_spam_check

    # Jev policy thresholds. We only act on CLEAR spam, so the bar for a single signal is high.
    # Starting points: validate against labeled moderation outcomes before tightening.
    CLEAR = 0.85
    SUPPORTING = 0.5
    JEV_BODY_CHARS = 12_000

    # @param article [Object] The article object to be checked.
    #   It should respond to `title`, `body_markdown`, `user`, and `subforem_id`.
    def initialize(article)
      @article = article
      @selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      return if @selection.jev?

      @ai_client = Ai::Base.new(model: @selection.gemini_model, wrapper: self, affected_user: article.user,
                                affected_content: article)
    end

    ##
    # Asks the AI if the article is spam and returns a boolean.
    #
    # @return [Boolean] true if the article is likely spam, false otherwise.
    def spam?
      return spam_via_jev? if @selection.jev?

      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue Ai::Base::ProhibitedContentError
      raise
    rescue StandardError => e
      Rails.logger.error("Article Spam Check failed: #{e}")
      false
    end

    private

    # --- Jev (TypeSafe System One) ---

    def spam_via_jev?
      result = jev_client.evaluate(state: jev_state, questions: jev_questions)
      spam_from_jev?(result)
    end

    def jev_client
      Ai::TypeSafe::Client.new(model: @selection.model, wrapper: self, affected_user: @article.user,
                               affected_content: @article, **Ai::TypeSafe::Client::FAIL_FAST)
    end

    # Builds the structured state payload passed to Jev for spam evaluation.
    # @return [Hash]
    def jev_state
      article_state = { title: @article.title, body: @article.body_markdown.to_s.truncate(JEV_BODY_CHARS) }
      if @article.respond_to?(:status?) && @article.status?
        article_state[:format] = "status post: a short update or commentary where title is the full post text"
      end
      community_state = { description: community_description.presence || "No community description provided." }
      community_state[:content_advisement] = content_advisement_spec if content_advisement_spec.present?
      community_state[:tag_moderation_instructions] = tag_instructions if tag_instructions.any?

      state = {
        community: community_state,
        article: article_state
      }
      state[:author_recent_article_titles] = recent_titles if recent_titles.any?
      state
    end

    def jev_questions
      questions = {
        advertisement: noul(
          {
            question: "Is `article` primarily an advertisement or marketing pitch for a product, service, or business?",
            focus: "Judge the article's main purpose, not whether it mentions a product."
          },
          yes: "It exists mainly to sell or promote, offering readers little value unless they buy or click.",
          no: {
            what: "It mainly teaches, discusses, asks, or shares experience.",
            includes: "An honest, relevant launch announcement, or a tutorial that happens to use a product."
          },
        ),
        malicious: noul(
          "Does `article` try to phish readers, send them to a scam, or ask for credentials or payment details?",
        ),
        gibberish: noul(
          "Is `article.body` gibberish, keyword stuffing, or filler text with no coherent meaning?",
        ),
        link_vehicle: noul(
          {
            question: "Does `article` exist mainly to carry an outbound promotional or traffic-funnel link, " \
                      "with little self-contained value of its own?",
            includes: "Teaser/summary link-drop funnels that only summarize or tease a topic in order to " \
                      "push readers to click an external blog, newsletter, affiliate link, or commercial site."
          },
        ),
        off_topic: noul(
          "Is the subject of `article` unrelated to the purpose described in `community.description` " \
          "(and `community.content_advisement` if present)?",
        ),
        good_faith: noul(
          {
            question: "Is `article` a good-faith attempt to contribute something useful directly on this platform " \
                      "to readers of this community, even if it is short or imperfect?",
            no: {
              includes: "Off-topic SEO filler, commercial marketing copy, or teaser/summary link-drop posts " \
                        "that require clicking an external link to get the actual substance."
            }
          },
        )
      }
      if recent_titles.any?
        questions[:repetitive_promotion] = noul(
          "Do `author_recent_article_titles` and `article.title` together show the author repeatedly posting " \
          "promotional content?",
        )
      end
      if tag_instructions.any?
        questions[:violates_tag_rules] = noul(
          "Does `article` break any rule in `community.tag_moderation_instructions`?",
        )
      end
      questions
    end

    # Explicit policy over independent signals. Kept in code so thresholds can be tuned
    # without rewriting questions.
    def spam_from_jev?(result)
      advertisement = result.noul(:advertisement)
      link_vehicle = result.noul(:link_vehicle)
      good_faith = result.noul(:good_faith)

      return true if result.noul(:malicious) >= CLEAR
      return true if [advertisement, link_vehicle, result.noul(:gibberish)].max >= CLEAR &&
        good_faith < SUPPORTING
      # Off-topic content that is also promotional or not a good-faith contribution is spam.
      return true if result.noul(:off_topic) >= CLEAR &&
        ([advertisement, link_vehicle].max >= SUPPORTING || good_faith < SUPPORTING)
      return true if result.key?(:repetitive_promotion) &&
        result.noul(:repetitive_promotion) >= CLEAR &&
        [advertisement, link_vehicle].max >= SUPPORTING
      return true if result.key?(:violates_tag_rules) &&
        result.noul(:violates_tag_rules) >= CLEAR && good_faith < SUPPORTING

      false
    end

    # Resolves the community description for the article's subforem, falling back to the
    # default subforem and global settings when needed.
    # @return [String, nil]
    def community_description
      @community_description ||= resolve_community_description(@article.subforem_id)
    end

    # Resolves the expanded content advisement playbook for the article's subforem.
    # @return [String, nil]
    def content_advisement_spec
      @content_advisement_spec ||= resolve_content_advisement_spec(@article.subforem_id)
    end

    def recent_titles
      @recent_titles ||= @article.user.articles.where.not(id: @article.id).last(10).map(&:title)
    end

    def tag_instructions
      @tag_instructions ||= @article.tags.where.not(moderation_instructions: [nil, ""])
        .pluck(:name, :moderation_instructions)
        .map { |name, instructions| { tag: name, instructions: instructions } }
    end

    # --- Gemini ---

    ##
    # Gathers all necessary context and constructs a detailed prompt for the AI.
    # @return [String] The prompt to be sent to the Gemini API.
    def build_prompt
      # Gather the user's 10 most recent article titles as historical context.
      user_history = @article.user.articles.last(10).map.with_index(1) do |a, i|
        "Article #{i}: \"#{a.title}\""
      end.join("\n")

      # Gather custom tag moderation instructions
      tag_instructions_text = build_tag_instructions_context
      advisement_text = if content_advisement_spec.present?
                          "\n\nContent Advisement Playbook:\n#{content_advisement_spec}"
                        else
                          ""
                        end

      <<~PROMPT
        Analyze the following article for spam. Your answer must be a single word: YES or NO.

        Primary Task: Determine if the "ARTICLE TO CHECK" is spam. Spam includes, but is not limited to:
        - Unsolicited advertisements or pure marketing content.
        - Phishing links or malicious URLs.
        - Gibberish, low-quality, or completely irrelevant text.
        - Off-topic posts that do not align with the community's purpose.
        - Low-value content created primarily to house a promotional link, or "teaser/summary" link-drop funnels that withhold substance to drive clicks to an external URL.
        - Repetitive, promotional articles posted by the same user.

        Simple, non-spammy promotion via links is acceptable if it is relevant to the community and adds self-contained value on-platform. We are looking for CLEAR spam, not borderline cases.
        Good articles can be long posts, short questions, or anything that may add value to the community.

        Here is the context:

        1.  **Community Context** (The community this article was posted in):
            ---
            #{community_description.presence || 'No community description provided.'}#{advisement_text}#{tag_instructions_text}
            ---

        2.  **The Author's Recent Article History**:
            ---
            #{user_history.empty? ? 'No article history available.' : user_history}
            ---

        3.  **ARTICLE TO CHECK -- The Article I ultimately want you to check is the following:**:
            ---
            Title: #{@article.title}
            Body#{@article.body_markdown}
            ---

        Analyze the "ARTICLE TO CHECK" based on all the provided context.
        The "Community Context" is especially important for determining if the article's topic is appropriate.
        The author's history can reveal patterns of spamming.
        An article is NOT spam if it is a good-faith attempt to contribute to the community, even if it is not perfect.

        Based on all the context, is the "ARTICLE TO CHECK" itself CLEARLY spam? Answer only with YES or NO.
      PROMPT
    end

    ##
    # Parses the AI's direct YES/NO response.
    # @param response [String] The text response from the AI.
    # @return [Boolean]
    def parse_response(response)
      # Check if the response contains "YES", ignoring case and leading/trailing whitespace.
      !response.nil? && response.strip.upcase == "YES"
    end

    def build_tag_instructions_context
      tag_instructions = @article.tags.where.not(moderation_instructions: [nil, ""]).pluck(:name, :moderation_instructions)
      return "" if tag_instructions.empty?

      instructions_list = tag_instructions.map do |name, inst|
        "- ##{name}: #{inst}"
      end.join("\n")

      <<~CONTEXT

        Custom Tag Moderation Instructions:
        #{instructions_list}
      CONTEXT
    end
  end
end
