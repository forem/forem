module Organizations
  class BustCacheJob < ApplicationJob
    queue_as :organizations_bust_cache

    def perform(organization_id, slug, cache_buster = CacheBuster.new)
      organization = Organization.find_by(id: organization_id)

      return unless organization

      cache_buster.bust_organization(organization, slug)
    end
  end
end
