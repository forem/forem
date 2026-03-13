# Exposes the `rolify` gem's `users_roles` table via ActiveRecord
class UserRole < ApplicationRecord
  self.table_name = "users_roles"

  belongs_to :user
  belongs_to :role

  after_commit :bust_user_profile_cache, on: %i[create destroy]

  private

  def bust_user_profile_cache
    return unless user

    user.touch
    Users::BustCacheWorker.perform_async(user.id)
  end
end
