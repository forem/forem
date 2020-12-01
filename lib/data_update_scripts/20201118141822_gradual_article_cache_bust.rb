module DataUpdateScripts
  class GradualArticleCacheBust
    def run
      # This script is designed to bust the cache on article pages sufficient such that significant changes to
      # CSS will not create meaningful visual regressions for most users.
      # All articles have their caches naturally recycle once per day to finalize the transition.

      # This uses exponential backoff in order to bust the caches of more recent articles first, but not
      # bust everything in too short a period, so that the edge cache can gradually re-heat without everything
      # going cold at once. Articles with high "hotness score" (e.g. more recent) are the ones most in need of busting.

      # It only busts the "?i=i" variant of the path which is the "internal nav" version, aka the page when swapped
      # with internal navigation, not the one landed on directly (which wouldn't have cache mismatches)
      relation = Article.published.order(hotness_score: :desc).select(:path)

      relation.limit(1500).each_with_index do |article, index|
        n = index + 300 # + 300 gives the server time to boot up
        BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "#{article.path}?i=i")
      end
      relation.offset(1500).limit(3000).each_with_index do |article, index|
        n = (index * 3) + 450
        BustCachePathWorker.set(queue: :medium_priority).perform_in(n.seconds, "#{article.path}?i=i")
      end
    end
  end
end
