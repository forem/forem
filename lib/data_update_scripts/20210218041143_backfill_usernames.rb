module DataUpdateScripts
  class BackfillUsernames
    def run
      # Now that we have a DB constraint "username IS NOT NULL" this script will always fail
      # User.where(username: nil).find_each do |user|
      #   user.update(username: "user#{user.id}")
      # end
    end
  end
end
