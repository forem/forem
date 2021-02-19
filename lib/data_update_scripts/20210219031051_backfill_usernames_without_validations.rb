module DataUpdateScripts
  class BackfillUsernamesWithoutValidations
    def run
      User.where(username: nil).find_each do |user|
        user.update_column(:username, "user#{user.id}")
      end
    end
  end
end
