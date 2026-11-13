module EdgeCache
  class BustPage
    def self.call(slug, organization: nil, user: nil)
      return unless slug

      # Page responses carry `show-page-<slug>` on every URL that serves them
      # (`/page/:slug`, `/:slug`, `/:slug/`, and InstantClick `?i=` fetches), and
      # organization/user pages also carry the owner's surrogate keys.
      keys = ["show-page-#{slug}", *EdgeCache::LegacySlugRedirectKeys.call(slug)]
      fallback_paths = [
        "/page/#{slug}",
        "/#{slug}",
        "/#{slug}/",
        "/#{slug}?mode=embed",
      ]

      if organization
        keys << organization.record_key
        fallback_paths << "/#{organization.slug}"
      end

      if user
        keys << user.record_key
        keys << user.profile_identity_record_key
        fallback_paths << user.path
      end

      EdgeCache::PurgeByKey.call(keys, fallback_paths: fallback_paths)
    end
  end
end
