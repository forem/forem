class BulkAssignRole < ApplicationRecord
  validates :email, :user_id, presence: true
end
