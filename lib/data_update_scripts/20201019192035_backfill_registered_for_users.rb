module DataUpdateScripts
  class BackfillRegisteredForUsers
    def run
      return if User.created_at.nil?

      users = User.where(registered: false).or(User.where(registered_at: nil))
      users.find_each do |user|
        user.update_columns(registered: true, registered_at: user.created_at)
      end
    end
  end
end
