module Ai
  ##
  # Analyzes a comment to determine if it is likely spam.
  #
  # This class gathers context from the comment, its parent post, and the
  # user's comment history to create a detailed prompt for the AI.
  #
  # When the :comment_spam_check function is set to Jev (see Ai::FunctionConfig), the
  # holistic YES/NO prompt is replaced by narrow TypeSafe Noul questions combined by the
  # explicit policy in #spam_from_jev?.
  class CommentCheck
    include Ai::TypeSafe::Questions

    VERSION = "1.1".freeze
    FUNCTION_KEY = :comment_spam_check

    # Jev policy thresholds: act only on clear spam. Validate against labeled outcomes.
    CLEAR = 0.85
    SUPPORTING = 0.5

    # @param comment [Object] The comment object to be checked.
    #   It should respond to `body_markdown`, `commentable`, and `user`.
    def initialize(comment)
      @comment = comment
      @selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      return if @selection.jev?

      @ai_client = Ai::Base.new(model: @selection.gemini_model, wrapper: self, affected_content: comment,
                                affected_user: comment.user)
    end

    ##
    # Asks the AI if the comment is spam and returns a boolean.
    #
    # @return [Boolean] true if the comment is likely spam, false otherwise.
    def spam?
      return spam_via_jev? if @selection.jev?

      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error(e)
      false
    end

    private

    # --- Jev (TypeSafe System One) ---

    def spam_via_jev?
      client = Ai::TypeSafe::Client.new(model: @selection.model, wrapper: self, affected_content: @comment,
                                        affected_user: @comment.user)
      spam_from_jev?(client.evaluate(state: jev_state, questions: jev_questions))
    end

    def jev_state
      post = @comment.commentable
      state = {
        post: { title: post.title, body: post.body_markdown.to_s.truncate(1_500) },
        comment: @comment.body_markdown.to_s.truncate(4_000)
      }
      state[:author_recent_comments] = recent_comments if recent_comments.any?
      state
    end

    def jev_questions
      questions = {
        advertisement: noul(
          "Is `comment` an unsolicited advertisement for a product, service, or business?",
          no: { includes: "Recommending a relevant tool or resource while answering `post`." },
        ),
        malicious: noul(
          "Does `comment` try to phish readers, send them to a scam, or ask for credentials or payment details?",
        ),
        gibberish: noul("Is `comment` gibberish or text with no coherent meaning?"),
        off_context_promotion: noul(
          "Is `comment` unrelated to `post` and used to promote something?",
        ),
        inserted_link: noul(
          {
            question: "Does `comment` slip a promotional link into an otherwise on-topic reply?",
            focus: "Look for a link that serves the commenter's business rather than the discussion."
          },
          no: "It has no link, or its links directly support the point being made about `post`.",
        ),
        genuine_reply: noul(
          "Does `comment` genuinely respond to or discuss `post`?",
        )
      }
      if recent_comments.any?
        questions[:repetitive_promotion] = noul(
          "Do `author_recent_comments` show the author posting the same or similar promotional messages " \
          "across different posts?",
        )
      end
      questions
    end

    # Mirrors the original guidance: history only matters when the comment itself looks spammy.
    def spam_from_jev?(result)
      return true if result.noul(:malicious) >= CLEAR

      # A promotional link slipped into an on-topic reply is spam by definition, so it is not
      # vetoed by genuine_reply the way the off-topic signals are.
      return true if result.noul(:inserted_link) >= CLEAR

      off_topic_signal = [
        result.noul(:advertisement),
        result.noul(:gibberish),
        result.noul(:off_context_promotion),
      ].max
      return true if off_topic_signal >= CLEAR && result.noul(:genuine_reply) < SUPPORTING

      direct = [off_topic_signal, result.noul(:inserted_link)].max
      return true if direct >= SUPPORTING && result.key?(:repetitive_promotion) &&
        result.noul(:repetitive_promotion) >= CLEAR

      false
    end

    def recent_comments
      @recent_comments ||= @comment.user.comments.where.not(id: @comment.id).last(10)
        .map { |c| c.body_markdown.to_s.first(1_000) }
    end

    # --- Gemini ---

    ##
    # Gathers all necessary context and constructs a detailed prompt for the AI.
    # @return [String] The prompt to be sent to the Gemini API.
    def build_prompt
      user_history = @comment.user.comments.last(10).map.with_index(1) do |c, i|
        "Comment #{i}: \"#{c.body_markdown.first(1_000)}\""
      end.join("\n")

      <<~PROMPT
        Analyze the following comment for spam. Your answer must be a single word: YES or NO.

        Primary Task: Determine if the "COMMENT TO CHECK" is spam. Spam includes, but is not limited to:
        - Unsolicited advertisements.
        - Phishing links or malicious URLs.
        - Gibberish or irrelevant text.
        - Out-of-context replies used for promotion.
        - Insertion of link in otherwise in-context reply.
        - Repetitive, promotional messages posted across different content.

        Here is the context:

        1.  **The Parent Content Post** (The post the comment was left in reply to):
            ---
            Title: #{@comment.commentable.title}
            Body#{'(truncated)' if @comment.commentable.body_markdown.size > 1500}: #{@comment.commentable.body_markdown.first(1_500)}
            ---

        2.  **The User's Recent Comment History**:
            ---
            #{user_history.empty? ? 'No comment history available.' : user_history}
            ---

        3.  **COMMENT TO CHECK -- The Comment I ultimately want you to check and confirm is the following:**:
            ---
            #{@comment.body_markdown}
            ---

        If this comment is clearly not spam, and is a helpful part of the community, do not consider the history at all.
        Only consider the comment history and the post it is replying to if the comment in question may be spam itself.

        Based on all the context, is the "COMMENT TO CHECK" itself CLEARLY spam? Answer only with YES or NO.
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
  end
end
