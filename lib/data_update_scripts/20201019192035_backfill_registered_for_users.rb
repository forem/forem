module DataUpdateScripts
  class BackfillRegisteredForUsers
    def run
      users = User.where(registered: false).or(User.where(registered_at: nil))
      users.find_each do |user|
        next if user.created_at.nil? || user.invitation_accepted_at.nil?

        user.update_columns(registered: true, registered_at: user.invitation_accepted_at)
      end
    end
  end
end
