module DataUpdateScripts
  class ResaveToBustCacheForImgproxy
    def run
      return unless ENV["FOREM_CONTEXT"] == "forem_cloud"

      User.find_each do |user|
        CacheBuster.bust_user(user)
      end

      Organization.find_each do |organization|
        EdgeCache::BustOrganization.call(organization, organization.slug)
      end

      Article.find_each(&:save)
      Comment.find_each(&:save)
    end
  end
end
