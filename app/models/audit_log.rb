class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :data, presence: true

  MODERATOR_AUDIT_LOG_CATEGORY = "moderator.audit.log".freeze
  ADMIN_API_AUDIT_LOG_CATEGORY = "admin_api.audit.log".freeze

  # Returns audit logs where the given user was the target of an action.
  # Tries to match the user using either:
  #   - `target_user_id` (string or int)
  #   - `reactable_id` (string or int) if `reactable_type` = "User"
  scope :on_user, lambda { |user|
    uid = user.id
    where("data @> :target_int OR data @> :target_str " \
          "OR (data @> :user_reactable_type AND (data @> :user_reactable_id_str OR data @> :user_reactable_id_int))",
          target_int: { target_user_id: uid }.to_json,
          target_str: { target_user_id: uid.to_s }.to_json,
          user_reactable_type: { reactable_type: "User" }.to_json,
          user_reactable_id_str: { reactable_id: uid.to_s }.to_json,
          user_reactable_id_int: { reactable_id: uid }.to_json)
  }
end
