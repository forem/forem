module Users
  class Suspended < ApplicationRecord
    self.table_name = "suspended_users"

    validates :username_hash, presence: true, uniqueness: true

    def self.check_username(username)
      where(username_hash: Digest::SHA256.hexdigest(username)).any?
    end
  end
end
