module EdgeCache
  class BustPage
    def self.call(slug, organization: nil)
      return unless slug

      cache_bust = EdgeCache::Bust.new
      cache_bust.call("/page/#{slug}")
      cache_bust.call("/#{slug}")

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
