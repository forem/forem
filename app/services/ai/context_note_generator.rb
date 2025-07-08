module Ai
  class ContextNoteGenerator

    def initialize(article, tag)
      @article = article
      @tag = tag
      @ai_client = Ai::Base.new
    end

    def call
      return unless @article && @tag && @tag.context_note_instructions.present?
      prompt = build_prompt
      response = @ai_client.call(prompt) if prompt.present?

      return if response.blank? || response.strip == "INVALID"

      # Create the context note with the response
      context_note = ContextNote.create!(
        body_markdown: response.strip,
        article: @article,
        tag: @tag
      )
    rescue StandardError => e
      Rails.logger.error("Context Note Generation failed: #{e}")
    end

    def build_prompt
      # tag has context_note_instructions
      # We should generate a context note for the instructions based on the output of what we get from the prompt.
      instructions = @tag.context_note_instructions.strip
      return if instructions.blank?

      <<~PROMPT
        You are an AI assistant that generates context notes for articles.
        The article is titled "#{@article.title}" and has the following content:
        #{@article.body_markdown}

        Based on the above article, please generate a context note that follows these instructions:
        #{instructions}

        If the article does not fit the valid criteria based on the instructions, return only the word "INVALID" and nothing else.
      PROMPT
    end
  end
end