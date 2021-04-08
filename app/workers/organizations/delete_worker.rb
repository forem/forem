module Organizations
  class DeleteWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    # user_id - the user who deletes the organization
    def perform(organization_id, user_id)
      org = Organization.find_by(id: organization_id)
      return unless org

      Organizations::Delete.call(org)

      user = User.find_by(id: user_id)
      return unless user

      user.touch(:organization_info_updated_at)
      EdgeCache::BustUser.call(user)

      # notify user that the org was deleted
      # NotifyMailer.with(name: user.name, email: user.email).account_deleted_email.deliver_now
    end
  end
end
