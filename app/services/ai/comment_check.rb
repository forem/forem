module Ai
  ##
  # Analyzes a comment to determine if it is likely spam.
  #
  # This class gathers context from the comment, its parent post, and the
  # user's comment history to create a detailed prompt for the AI.
  class CommentCheck
    # @param comment [Object] The comment object to be checked.
    #   It should respond to `body_markdown`, `commentable`, and `user`.
    def initialize(comment)
      @ai_client = Ai::Base.new
      @comment = comment
    end

    ##
    # Asks the AI if the comment is spam and returns a boolean.
    #
    # @return [Boolean] true if the comment is likely spam, false otherwise.
    def spam?
      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      false
    end

    private

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
        - Repetitive, low-quality messages posted across different content.

        Here is the context:

        1.  **The Parent Content** (The post the comment was left on):
            ---
            #{@comment.commentable.body_markdown.first(5_000)}
            ---

        2.  **The User's Recent Comment History** (Their last 10 comments):
            ---
            #{user_history.empty? ? 'No comment history available.' : user_history}
            ---

        3.  **The Comment to Check**:
            ---
            #{@comment.body_markdown}
            ---

        Based on all the context, is the "COMMENT TO CHECK" spam? Answer only with YES or NO.
      PROMPT
    end

    ##
    # Parses the AI's direct YES/NO response.
    # @param response [String] The text response from the AI.
    # @return [Boolean]
    def parse_response(response)
      # Check if the response contains "YES", ignoring case and leading/trailing whitespace.
      !response.nil? && response.strip.upcase == 'YES'
    end
  end
end