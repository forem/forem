module Concepts
  class AnchorGenerator
    VERSION = "1.0".freeze

    def initialize(concept)
      @concept = concept
      @ai_client = Ai::Base.new(wrapper: self)
    end

    def call
      if @concept.description.blank?
        @concept.description = generate_description
      end

      return if @concept.description.blank?

      embedding = generate_embedding
      return if embedding.blank?

      @concept.anchor_embedding = embedding
    end

    private

    def generate_description
      prompt = <<~PROMPT
        You are an expert technical editor.
        Write a concise, 2-3 sentence definition/description for the developer concept: "#{@concept.name}".
        Focus on what it is, its key characteristics, and its relevance to developers.
        Do not write any introductory or conversational text, just output the description directly.
      PROMPT

      begin
        description = @ai_client.call(prompt)
        description&.strip
      rescue StandardError => e
        Rails.logger.error(
          "Concepts::AnchorGenerator failed to generate description for #{@concept.name}: #{e.message}",
        )
        nil
      end
    end

    def generate_embedding
      text_to_embed = <<~TEXT
        Concept: #{@concept.name}
        Description: #{@concept.description}
      TEXT

      begin
        embedding_client = Ai::Embedding.new(wrapper: self)
        embedding_client.call(text_to_embed, task_type: "RETRIEVAL_DOCUMENT", output_dimensionality: 768)
      rescue StandardError => e
        Rails.logger.error("Concepts::AnchorGenerator failed to generate embedding for #{@concept.name}: #{e.message}")
        nil
      end
    end
  end
end
