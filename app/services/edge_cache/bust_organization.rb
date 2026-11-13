module EdgeCache
  class BustOrganization
    def self.call(organization, slug)
      return unless organization && slug

      keys = organization.respond_to?(:record_key) ? [organization.record_key] : []
      org_id = organization.respond_to?(:id) ? organization.id : nil
      keys.concat(EdgeCache::LegacySlugRedirectKeys.call(slug, exclude_organization_id: org_id))
      fallback_paths = lambda do
        paths = ["/#{slug}"]
        if organization.respond_to?(:old_slug) && organization.old_slug.present?
          paths << "/#{organization.old_slug}"
        end
        if organization.respond_to?(:old_old_slug) && organization.old_old_slug.present?
          paths << "/#{organization.old_old_slug}"
        end
        paths.concat(organization.articles.pluck(:path)) if organization.respond_to?(:articles)
        paths.uniq
      end

      # Organization profile, custom domain, README, and published article responses all carry
      # the organization's surrogate key, so Fastly evicts them in one call without iterating
      # over every article path. Self-hosted Nginx/OpenResty resolves fallback_paths lazily.
      EdgeCache::PurgeByKey.call(keys, fallback_paths: fallback_paths)
    end
  end
end
