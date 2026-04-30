module Ai
  class ArticleSummaryGenerator
    VERSION = "1.0".freeze
    MAX_RETRIES = 2
    MIN_WORDS = 50
    MAX_WORDS = 60
    ARTICLE_BODY_CHAR_LIMIT = 4000

    def initialize(article)
      @article = article
      @ai_client = Ai::Base.new(wrapper: self, affected_content: @article)
    end

    def call
      return unless @article

      retries = 0
      extra_emphasis = ""

      begin
        prompt = build_prompt(extra_emphasis)
        response = @ai_client.call(prompt)
        return if response.blank?

        summary = response.strip.gsub(/^["']|["']$/, "")
        word_count = summary.split(/\s+/).size

        unless (MIN_WORDS..MAX_WORDS).cover?(word_count)
          raise "Summary invalid word count: #{word_count} (expected #{MIN_WORDS}-#{MAX_WORDS})"
        end

        @article.update_columns(ai_summary: summary,
                                ai_summary_prompt_version: VERSION,
                                ai_summary_generated_at: Time.current,
                                updated_at: Time.current)
      rescue StandardError => e
        if retries < MAX_RETRIES
          retries += 1
          extra_emphasis = "RETRY: Your previous response had the wrong word count. You MUST produce between #{MIN_WORDS} and #{MAX_WORDS} words. Count carefully."
          retry
        else
          Rails.logger.error("Article Summary Generation failed for article #{@article.id}: #{e.message}")
        end
      end
    end

    private

    def build_prompt(extra_emphasis)
      article_text = @article.body_markdown.to_s[0...ARTICLE_BODY_CHAR_LIMIT]

      <<~PROMPT
        You are writing a short summary that will appear under the title of a
        published article. Write in a neutral, descriptive voice, like a
        magazine dek or a book-jacket blurb. State the substance of the piece
        directly, without narration.

        Article Title: "#{@article.title}"
        Article Content (truncated):
        #{article_text}

        Voice and framing:
        - NEUTRAL perspective. Not first person, not third-party descriptive.
        - Do NOT use "I", "we", "my", "our". This is not the author speaking.
        - Do NOT use "the article", "the post", "this piece", "this essay",
          "the author", "the writer", or ANY other meta-reference to the article
          itself or whoever wrote it.
        - Do NOT use phrases like "explores", "argues", "considers",
          "posits", "concludes", "contends" when they would be attached to
          a meta-subject like "this piece" or "the article".
        - Just present the ideas, claims, or questions directly, as
          standalone statements.
        - Bad (third-party):  "The article considers whether modern AI would
          have accelerated web development."
        - Bad (first person): "I wonder whether modern AI would have
          accelerated web development."
        - Good (neutral):     "If modern AI had emerged a decade earlier,
          would it have accelerated web development or merely entrenched
          existing patterns?"

        Length and form:
        - MUST be between #{MIN_WORDS} and #{MAX_WORDS} words. Rewrite the
          summary until it fits that window.
        - Plain prose in complete sentences. No markdown, lists, or headings.
        - Do not repeat the title verbatim.
        - Avoid clickbait or sensational language.

        Respond ONLY with the summary text, no preamble or explanation.

        #{extra_emphasis}
      PROMPT
    end
  end
end
