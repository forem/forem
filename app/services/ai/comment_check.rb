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
      Rails.logger.error(e)
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
        - Repetitive, promotional messages posted across different content.

        Here is the context:

        1.  **The Parent Content Post** (The post the comment was left in reply to):
            ---
            Title: #{@comment.commentable.title}
            Body#{ "(truncated)" if @comment.commentable.body_markdown.size > 1500}: #{@comment.commentable.body_markdown.first(1_500)}
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
      !response.nil? && response.strip.upcase == 'YES'
    end
  end
end