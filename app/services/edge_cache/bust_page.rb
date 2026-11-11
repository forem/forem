module EdgeCache
  class BustPage
    def self.call(slug, organization: nil)
      return unless slug

      # Page responses carry `show-page-<slug>` on every URL that serves them
      # (`/page/:slug`, `/:slug`, `/:slug/`, and InstantClick `?i=` fetches), and
      # organization pages also carry the organization's surrogate key across
      # profile and custom-domain routes.
      keys = ["show-page-#{slug}", *EdgeCache::LegacySlugRedirectKeys.call(slug)]
      fallback_paths = [
        "/page/#{slug}",
        "/#{slug}",
        "/#{slug}/",
      ]

      if organization
        keys << organization.record_key
        fallback_paths << "/#{organization.slug}"
      end

      EdgeCache::PurgeByKey.call(keys, fallback_paths: fallback_paths)
      cutover_paths = [
        *fallback_paths,
        ("/bounty" if slug == "security"),
        ("/faq" if slug == "faq"),
      ].compact
      EdgeCache::CutoverUrlBust.call(cutover_paths)
    end
  end
end
