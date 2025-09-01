module Comments
  class HandleSpamWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      Spam::Handler.handle_comment!(comment: comment) if comment
    end
  end
end
