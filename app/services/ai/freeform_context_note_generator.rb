module Ai
  class FreeformContextNoteGenerator
    VERSION = "1.0"
    MAX_RETRIES = 2

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
        
        return if response.blank? || response.strip.length > 300 # sanity check

        # Strip response and remove surrounding quotes if the AI added them
        note_text = response.strip.gsub(/^["']|["']$/, "")
        
        if note_text.length <= 50
          ContextNote.create!(
            body_markdown: note_text,
            article: @article,
          )
        else
          raise "Note too long: #{note_text.length} characters"
        end
      rescue => e
        if retries < MAX_RETRIES
          retries += 1
          extra_emphasis = "RETRY: Your previous response was too long. You MUST ensure the response is FEWER THAN 50 CHARACTERS. Be extremely brief. One short sentence only."
          retry
        else
          Rails.logger.error("Freeform Context Note Generation failed: #{e.message}")
        end
      end
    end

    private

    def build_prompt(extra_emphasis)
      article_text = @article.body_markdown.to_s[0..1500]
      top_comments = @article.comments.order(score: :desc).limit(3).pluck(:body_markdown).map { |c| "- #{c.to_s[0..300]}" }.join("\n")

      <<~PROMPT
        You are an AI assistant tasked with generating a freeform context note for a highly engaging article.
        
        Article Title: "#{@article.title}"
        Article Content (truncated): 
        #{article_text}
        
        Top Comments:
        #{top_comments}
        
        Instructions:
        Provide a general helpful hint about what's interesting and noteworthy about the post and/or the comments.
        The note MUST be fewer than 50 characters and be just a single short sentence. The more concise the better.
        It should complement the info in the title (do not re-hash the title).
        Do not overly summarize; just provide a bit of helpful extra context that might be interesting to someone browsing.
        Do not use clickbait or sensational language; just a basic interesting tidbit.
        Respond ONLY with the context note itself, no other text or explanation.

        #{extra_emphasis}
      PROMPT
    end
  end
end
