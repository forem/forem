module Pages
  class BustCacheWorker < BustCacheBaseWorker
    def perform(slug, organization_id = nil, user_id = nil)
      return if slug.blank?

      organization = Organization.find_by(id: organization_id) if organization_id
      user = User.find_by(id: user_id) if user_id
      EdgeCache::BustPage.call(slug, organization: organization, user: user)
    end
  end
end
