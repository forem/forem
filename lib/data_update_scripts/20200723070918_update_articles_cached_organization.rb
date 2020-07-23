module DataUpdateScripts
  class UpdateArticlesCachedOrganization
    ATTRIBUTES = %i[name slug username profile_image_90 profile_image_url].freeze

    def run
      Article.find_each do |article|
        next if article.cached_organization.blank?

        old_cached_org = article.cached_organization
        new_cached_org = Organization::CachedOrganization.new(*old_cached_org.to_h.values_at(*ATTRIBUTES))
        article.update(cached_organization: new_cached_org)
      end
    end
  end
end
