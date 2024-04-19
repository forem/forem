module Comments
  class CalculateScoreWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, lock: :until_executing

    def perform(comment_id)
      comment = Comment.find_by(id: comment_id)
      return unless comment

      Comments::CalculateScore.call(comment)
    end
  end
end
