module DataUpdateScripts
  class BackfillUsernames
    def run
      User.where(username: nil).find_each do |user|
        user.update(username: "user#{user.id}")
      end
    end
  end
end
