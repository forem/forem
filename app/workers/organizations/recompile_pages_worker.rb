module Organizations
  class RecompilePagesWorker
    include Sidekiq::Job

    sidekiq_options queue: :default, retry: 3, lock: :until_executing, on_conflict: :replace

    def perform(organization_id)
      organization = Organization.find_by(id: organization_id)
      return unless organization
      return unless FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])

      organization.pages.find_each do |page|
        begin
          page.recompile!
        rescue StandardError => e
          Rails.logger.error(
            "Organizations::RecompilePagesWorker failed to recompile page #{page.id} for org #{organization.id}: #{e.class} - #{e.message}",
          )
        end
      end
    end
  end
end
