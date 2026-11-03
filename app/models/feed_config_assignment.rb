class FeedConfigAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :subforem, optional: true
  belongs_to :feed_config, optional: true

  def self.visit_verifier
    Rails.application.message_verifier(:feed_config_visit)
  end

  def visit_token(host:)
    return unless persisted? && feed_config_id.present? && expires_at.present?

    self.class.visit_verifier.generate(
      { "assignment_id" => id, "user_id" => user_id, "subforem_id" => subforem_id,
        "feed_config_id" => feed_config_id, "expires_at" => expires_at.utc.iso8601(6), "host" => host },
      purpose: :feed_config_visit, expires_at: expires_at,
    )
  end
end
