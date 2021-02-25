class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :data, presence: true
end
