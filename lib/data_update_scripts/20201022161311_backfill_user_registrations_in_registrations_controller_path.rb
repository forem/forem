module DataUpdateScripts
  class BackfillUserRegistrationsInRegistrationsControllerPath
    def run
      # Users who _were not invited_ should by definition have registered already in order to exist
      User.where(registered_at: nil, invitation_sent_at: nil).find_each do |user|
        user.update_columns(registered_at: user.created_at, registered: true)
      end
    end
  end
end
