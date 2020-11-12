module DataUpdateScripts
  class BackfillRegisteredForUsers
    def run
      users = User.where.not(invitation_accepted_at: nil).where(registered: false).or(User.where(registered_at: nil))
      users.find_each do |user|
        user.update_columns(registered: true, registered_at: user.invitation_accepted_at)
      end
    end
  end
end
