module Moderator
  class DeleteUser < ManageActivityAndRoles
    attr_reader :user, :admin

    def self.call_delete_activity(admin:, user:)
      new(user: user, admin: admin).full_delete
    end

    def full_delete
      user.unsubscribe_from_newsletters
      delete_user_activity
      CacheBuster.new.bust("/#{user.old_username}")
      user.delete
    end
  end
end
