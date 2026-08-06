module Appeals
  # Sidekiq worker that runs AI re-assessment on a FlagAppeal
  class AiReviewWorker
    include Sidekiq::Job

    sidekiq_options queue: :default, lock: :until_executing, on_conflict: :replace

    def perform(appeal_id)
      appeal = FlagAppeal.find_by(id: appeal_id)
      return unless appeal&.open?

      results = Ai::AppealAssessor.new(appeal).evaluate

      # Ensure appeal status has not changed (e.g. resolved manually by an admin while AI evaluated)
      return unless appeal.reload.open?

      appeal.update!(
        ai_summary: results[:summary],
        ai_confidence_score: results[:confidence_score],
        ai_recommendation: results[:recommendation],
        status: :ai_reviewed,
      )

      # Optional auto-resolution for high-confidence false positives
      threshold = Settings::General.appeal_auto_unflag_threshold || 0.90
      if results[:recommendation] == "auto_unflag" && results[:confidence_score] >= threshold
        Appeals::Resolver.approve(appeal: appeal)
      end
    rescue StandardError => e
      Rails.logger.error("Appeals::AiReviewWorker failed for appeal ##{appeal_id}: #{e}")
      raise e
    end
  end
end
