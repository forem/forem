module Users
  class GenerateAiProfileImageWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      image = Images::ProfileImageGenerator.call(seed: user.id)
      return unless image

      user.profile_image = image
      user.save!
    rescue StandardError => e
      Rails.logger.error("Profile image generation failed for user #{user_id}: #{e.message}")
      Rails.error.report(e, context: { user_id: user_id })
    end
  end
end
