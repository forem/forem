class Articles::GenerateFreeformContextNoteWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform(article_id)
    article = Article.find_by(id: article_id)
    return unless article
    
    # Double check conditions
    return if article.score < 50 || article.comment_score < 25
    return if article.published_at.blank? || article.published_at < 1.week.ago
    return if article.context_notes.exists?
    
    Ai::FreeformContextNoteGenerator.new(article).call
  end
end
