module DataUpdateScripts
  class BackfillUserRegisteredAt
    def run
      User.where(registered_at: nil, registered: true).find_each do |user|
        user.update_column(:registered_at, user.created_at)
      end
    end
  end
end
