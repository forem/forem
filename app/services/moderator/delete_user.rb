module Moderator
  class DeleteUser < ManageActivityAndRoles
    attr_reader :user, :user_params

    def self.call(user:)
      Users::DeleteWorker.perform_async(user.id, true)
    end

    private

    def delete_user
      Users::DeleteWorker.new.perform(user.id, true)
    end
  end
end
