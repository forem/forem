module Users
  class SuspendedUsername < ApplicationRecord
    self.table_name_prefix = "users_"

    validates :username_hash, presence: true, uniqueness: true

    def self.hash_username(username)
      Digest::SHA256.hexdigest(username)
    end

    def self.previously_suspended?(username)
      where(username_hash: hash_username(username)).any?
    end

    # Convenience method for easily adding a suspended user
    def self.create_from_user(user)
      create!(username_hash: hash_username(user.username))
    end
  end
end
