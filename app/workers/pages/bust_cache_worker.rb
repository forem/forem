module Pages
  class BustCacheWorker < BustCacheBaseWorker
    def perform(slug, organization_id = nil, user_id = nil, event_id = nil)
      return if slug.blank?

      organization = Organization.find_by(id: organization_id) if organization_id
      if event_id
        event = Event.find_by(id: event_id)
        EdgeCache::BustPage.call(slug, organization: organization, event: event)
      elsif user_id
        user = User.find_by(id: user_id)
        EdgeCache::BustPage.call(slug, organization: organization, user: user)
      else
        EdgeCache::BustPage.call(slug, organization: organization)
      end
    end
  end
end
