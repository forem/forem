module Articles
  class GenerateContextNoteWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 5, lock: :until_executing

    def perform(article_id, tag_id)
      article = Article.find_by(id: article_id)
      return unless article

      tag = Tag.find_by(id: tag_id)
      return unless tag && tag.context_note_instructions.present?

      Ai::ContextNoteGenerator.new(article, tag).call
    end
  end
end