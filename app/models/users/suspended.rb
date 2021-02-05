module Users
  class Suspended < ApplicationRecord
    self.table_name = "suspended_users"

    validates :username_hash, presence: true, uniqueness: true

    def self.hash_username(username)
      Digest::SHA256.hexdigest(username)
    end

    def self.previously_banned?(username)
      where(username_hash: hash_username(username)).any?
    end

    # Convenience method for easily adding a suspended user
    def self.create_from_user(user)
      create!(username_hash: hash_username(user.username))
    end
  end
end
