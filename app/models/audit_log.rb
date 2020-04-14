class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
end
