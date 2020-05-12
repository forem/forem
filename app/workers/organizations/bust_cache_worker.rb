module Organizations
  class BustCacheWorker < BustCacheBaseWorker
    def perform(organization_id, slug)
      organization = Organization.find_by(id: organization_id)

      return unless organization

      CacheBuster.bust_organization(organization, slug)
    end
  end
end
