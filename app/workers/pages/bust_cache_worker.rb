module Pages
  class BustCacheWorker < BustCacheBaseWorker
    def perform(slug, organization_id = nil)
      return if slug.blank?

      organization = Organization.find_by(id: organization_id) if organization_id
      EdgeCache::BustPage.call(slug, organization: organization)
    end
  end
end
