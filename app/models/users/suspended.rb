module Users
  class Suspended < ApplicationRecord
    self.table_name = "suspended_users"

    validates :username_hash, presence: true, uniqueness: true
  end
end
