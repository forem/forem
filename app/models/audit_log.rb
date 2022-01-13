class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :data, presence: true

  MODERATOR_AUDIT_LOG_CATEGORY = "moderator.audit.log".freeze
end
