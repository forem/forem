module EdgeCache
  class BustPage
    def self.call(slug, organization: nil)
      return unless slug

      cache_bust = EdgeCache::Bust.new
      cache_bust.call("/page/#{slug}")
      cache_bust.call("/#{slug}")
      # The trailing-slash URL renders the same page but is a separate edge cache
      # entry, so without this purge it keeps serving the old page after an update.
      cache_bust.call("/#{slug}/")
      # Page responses carry this surrogate key on every URL that serves them,
      # including query variants such as the ?i= InstantClick fetch, which
      # the path purges above do not reach.
      EdgeCache::PurgeByKey.call("show-page-#{slug}")

      return unless organization

      # Organization pages are served from the org profile URLs (the readme
      # renders at /:slug, custom pages at /:slug/:suffix, and both again on
      # the org's custom domain). All of those responses carry the org's
      # surrogate key, so purge by key rather than enumerating every URL.
      EdgeCache::PurgeByKey.call(
        organization.record_key,
        fallback_paths: "/#{organization.slug}",
      )
    end
  end
end
