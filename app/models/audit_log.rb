class AuditLog < ApplicationRecord
  resourcify
  belongs_to :user

  validates :user_id, presence: true
end
