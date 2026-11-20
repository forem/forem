module EdgeCache
  class BustPodcast
    def self.call(path)
      return unless path

      slug = path.to_s.delete_prefix("/")
      EdgeCache::PurgeByKey.call(
        ["podcasts/#{slug}", "podcast_episodes_all", *EdgeCache::LegacySlugRedirectKeys.call(slug)],
        fallback_paths: ["/#{slug}", "/pod"],
      )
    end
  end
end
