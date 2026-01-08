class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :data, presence: true

  MODERATOR_AUDIT_LOG_CATEGORY = "moderator.audit.log".freeze
  ADMIN_API_AUDIT_LOG_CATEGORY = "admin_api.audit.log".freeze

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id category slug data created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end
end
