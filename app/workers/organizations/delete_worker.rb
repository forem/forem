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
      NotifyMailer.with(name: user.name, org_name: org.name, email: user.email).organization_deleted_email.deliver_now
    rescue StandardError => e
      ForemStatsClient.count("organizations.delete", 1,
                             tags: ["action:failed", "organization_id:#{org.id}", "user_id:#{user.id}"])
      Honeybadger.context({ organization_id: org.id, user_id: user.id })
      Honeybadger.notify(e)
    end
  end
end
