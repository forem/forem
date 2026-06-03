module Comments
  class GenerateEmbeddingWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment.respond_to?(:semantic_embedding)

      # Only generate if score is still >= 3
      return unless comment.score >= 3

      # Represent comment content
      text_to_embed = comment.body_markdown
      return if text_to_embed.blank?

      client = Ai::Embedding.new(affected_content: comment, wrapper: self)
      embedding = client.call(text_to_embed, task_type: "RETRIEVAL_DOCUMENT", output_dimensionality: 768)

      return unless embedding

      comment.update_column(:semantic_embedding, embedding)
      Concepts::ClassifyRecordWorker.perform_async("Comment", comment.id)
    end
  end
end
