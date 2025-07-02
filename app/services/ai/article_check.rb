module Ai
  ##
  # Analyzes an article to determine if it is likely spam.
  #
  # This class gathers context from the article, its author's publication
  # history, and the community it's posted in to create a detailed
  # prompt for the AI.
  class ArticleCheck
    # @param article [Object] The article object to be checked.
    #   It should respond to `title`, `body_markdown`, `user`, and `subforem_id`.
    def initialize(article)
      @ai_client = Ai::Base.new
      @article = article
    end

    ##
    # Asks the AI if the article is spam and returns a boolean.
    #
    # @return [Boolean] true if the article is likely spam, false otherwise.
    def spam?
      prompt = build_prompt
      response = @ai_client.call(prompt)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("Article Spam Check failed: #{e}")
      false
    end

    private

    ##
    # Gathers all necessary context and constructs a detailed prompt for the AI.
    # @return [String] The prompt to be sent to the Gemini API.
    def build_prompt
      # Gather the user's 10 most recent article titles as historical context.
      user_history = @article.user.articles.last(10).map.with_index(1) do |a, i|
        "Article #{i}: \"#{a.title}\""
      end.join("\n")

      # Fetch the description of the community the article is posted in.
      community_description = Settings::RateLimit.internal_content_description_spec(subforem_id: @article.subforem_id) || Settings::Community.community_description(subforem_id: @article.subforem_id)

      <<~PROMPT
        Analyze the following article for spam. Your answer must be a single word: YES or NO.

        Primary Task: Determine if the "ARTICLE TO CHECK" is spam. Spam includes, but is not limited to:
        - Unsolicited advertisements or pure marketing content.
        - Phishing links or malicious URLs.
        - Gibberish, low-quality, or completely irrelevant text.
        - Off-topic posts that do not align with the community's purpose.
        - Low-value content created primarily to house a promotional link.
        - Repetitive, promotional articles posted by the same user.

        Simple, non-spammy promotion via links is acceptable if it is relevant to the community and adds value. We are looking for CLEAR spam, not borderline cases.
        Good articles can be long posts, short questions, or anything that may add value to the community.

        Here is the context:

        1.  **Community Context** (The community this article was posted in):
            ---
            #{community_description.present? ? community_description : 'No community description provided.'}
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
      !response.nil? && response.strip.upcase == 'YES'
    end
  end
end