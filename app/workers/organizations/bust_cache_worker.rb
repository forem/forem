module Organizations
  class BustCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(organization_id, slug, cache_buster = CacheBuster)
      organization = Organization.find_by(id: organization_id)

      return unless organization

      cache_buster.bust_organization(organization, slug)
    end
  end
end
