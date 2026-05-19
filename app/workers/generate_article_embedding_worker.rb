class GenerateArticleEmbeddingWorker
  include Sidekiq::Job
  sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

  def perform(article_id)
    article = Article.find_by(id: article_id)
    return unless article && article.published? && article.respond_to?(:semantic_embedding)

    # Lightweight representation: Title, Tags, and first 1000 characters of the body
    text_to_embed = <<~TEXT
      Title: #{article.title}
      Tags: #{article.cached_tag_list}
      Summary: #{article.body_markdown.truncate(1000)}
    TEXT

    client = Ai::Embedding.new(affected_content: article, wrapper: self)
    embedding = client.call(text_to_embed, task_type: "RETRIEVAL_DOCUMENT", output_dimensionality: 768)

    if embedding
      article.update_column(:semantic_embedding, embedding)
      UpdateUserInterestEmbeddingWorker.perform_async(article.user_id, article.id)
    end
  end
end
