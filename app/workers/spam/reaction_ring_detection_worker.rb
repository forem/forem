# frozen_string_literal: true

module Spam
  # Background worker to detect reaction rings and adjust reputation modifiers
  class ReactionRingDetectionWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 3

    def perform(user_id)
      return unless user_id

      user = User.find_by(id: user_id)
      return unless user

      # Only run detection for users who meet the threshold
      return unless should_analyze_user?(user)

      # Run the ring detection
      detector = Spam::ReactionRingDetector.new(user_id)
      ring_detected = detector.call

      if ring_detected
        Rails.logger.info "Reaction ring detected for user #{user_id}"
        
        # Send notification to moderators if needed
        notify_moderators(user_id) if should_notify_moderators?
      end
    end

    private

    def should_analyze_user?(user)
      return false if user.any_admin? || user.super_moderator?
      return false if user.trusted?

      # Check if user has enough reactions in the past 3 months
      user.reactions
          .public_category
          .only_articles
          .where(created_at: 3.months.ago..)
          .count >= 50
    end

    def should_notify_moderators?
      # Only notify moderators for significant rings (5+ members)
      # This could be made configurable
      true
    end

    def notify_moderators(user_id)
      # Send a notification to moderators about the detected ring
      # This could be implemented as a Slack notification or internal notification
      Rails.logger.info "Reaction ring detected for user #{user_id} - moderators should be notified"
      
      # TODO: Implement actual moderator notification
      # Slack::Messengers::ReactionRingDetected.call(user_id: user_id)
    end
  end
end
