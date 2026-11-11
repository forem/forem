module Organizations
  class BustCacheWorker < BustCacheBaseWorker
    def perform(organization_id, slug)
      return unless organization_id && slug

      organization = Organization.find_by(id: organization_id)

      if organization
        EdgeCache::BustOrganization.call(organization, slug)
      else
        EdgeCache::PurgeByKey.call("organizations/#{organization_id}", fallback_paths: "/#{slug}")
        EdgeCache::CutoverUrlBust.call("/#{slug}")
      end
    end
  end
end
