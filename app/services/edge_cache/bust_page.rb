module EdgeCache
  class BustPage
    def self.call(slug, organization: nil, user: nil, event: nil)
      return unless slug

      # Page responses carry `show-page-<slug>` on every URL that serves them
      # (`/page/:slug`, `/:slug`, `/:slug/`, and InstantClick `?i=` fetches), and
      # organization/user/event pages also carry the owner's surrogate keys.
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

      if event
        keys << event.record_key
        suffix = slug.to_s.split("/").last
        event_base = "/events/#{event.event_name_slug}/#{event.event_variation_slug}"
        fallback_paths << event_base
        fallback_paths << "#{event_base}/p/#{suffix}"
        fallback_paths << "#{event_base}/embed/#{suffix}?mode=embed"
      end

      EdgeCache::PurgeByKey.call(keys, fallback_paths: fallback_paths)
    end
  end
end
