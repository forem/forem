module Ai
  ##
  # Analyzes a comment to determine if it is helpful and contextual,
  # particularly for welcome threads where we want to reward users who
  # offer helpful advice or provide contextual replies.
  #
  # This class uses AI to assess whether a comment:
  # - Offers helpful advice (for top-level comments)
  # - Is contextual and not spam (for replies)
  # - Contributes meaningfully to the welcome thread
  class CommentHelpfulnessAssessor
    # @param comment [Comment] The comment object to be assessed.
    # @param welcome_thread [Article] The welcome thread article for context.
    def initialize(comment, welcome_thread)
      @ai_client = Ai::Base.new
      @comment = comment
      @welcome_thread = welcome_thread
    end

    ##
    # Asks the AI if the comment is helpful and contextual.
    #
    # @return [Boolean] true if the comment is helpful/contextual, false otherwise.
    def helpful?
      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Comment Helpfulness Assessment failed: #{e}")
      # Fallback to false if AI assessment fails
      false
    end

    private

    ##
    # Gathers all necessary context and constructs a detailed prompt for the AI.
    # @return [String] The prompt to be sent to the Gemini API.
    def build_prompt
      is_top_level = @comment.parent_id.nil?
      comment_type = is_top_level ? "top-level comment" : "reply to another comment"

      parent_comment_context = if is_top_level
                                 "This is a top-level comment directly on the welcome thread."
                               else
                                 parent = @comment.parent
                                 "This is a reply to the following comment:\n" \
                                 "---\n" \
                                 "#{parent.body_markdown.first(500)}\n" \
                                 "---"
                               end

      <<~PROMPT
        Analyze the following comment in a Welcome Thread to determine if it qualifies for a "Warm Welcome" badge.

        **Context:**
        This is a #{comment_type} in a Welcome Thread where new community members introduce themselves.

        **Welcome Thread:**
        ---
        Title: #{@welcome_thread.title}
        Body: #{@welcome_thread.body_markdown.first(1000)}
        ---

        #{parent_comment_context}

        **Comment to Assess:**
        ---
        #{@comment.body_markdown}
        ---

        **Assessment Criteria:**

        For TOP-LEVEL COMMENTS (direct replies to the welcome thread):
        - Does it offer helpful advice, tips, or guidance to new members?
        - Does it welcome newcomers in a genuine and friendly way?
        - Does it share useful information about the community?
        - Is it substantive and meaningful (not just "welcome" or "hi")?

        For REPLIES (comments responding to other comments):
        - Is it contextual and relevant to the comment it's replying to?
        - Does it add value to the conversation?
        - Is it not spam, promotional, or off-topic?
        - Does it show genuine engagement with the other person's comment?

        **EXCLUDE comments that are:**
        - Spam or promotional content
        - Off-topic or irrelevant
        - Too short or low-effort (e.g., just "thanks" or "ok")
        - Generic or copy-pasted responses
        - Not contextual (for replies)

        **INCLUDE comments that are:**
        - Helpful advice or tips for new members
        - Genuine, warm welcomes with substance
        - Contextual replies that engage meaningfully
        - Sharing useful community information
        - Answering questions or providing guidance

        Based on the assessment criteria, is this comment helpful and contextual enough to qualify for a "Warm Welcome" badge?

        Answer only with YES or NO.
      PROMPT
    end

    ##
    # Parses the AI's direct YES/NO response.
    # @param response [String] The text response from the AI.
    # @return [Boolean]
    def parse_response(response)
      # Check if the response contains "YES", ignoring case and leading/trailing whitespace.
      !response.nil? && response.strip.upcase.include?("YES")
    end
  end
end

