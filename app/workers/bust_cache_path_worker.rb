# Retained as a rolling-deploy shim for pre-deploy enqueued jobs.
# Known global paths are translated to surrogate-key purges; arbitrary paths
# fall back to EdgeCache::Bust.
class BustCachePathWorker < BustCacheBaseWorker
  SURROGATE_KEY_BY_PATH = {
    "/" => "main_app_home_page",
    "/onboarding" => "onboarding-slideshow",
    "/onboarding/tags" => "tags",
    "/feed" => "articles-feed",
    "/feed.xml" => "articles-feed",
    "/rss" => "articles-feed",
    "/llms.txt" => "llms_page",
    "/async_info/navigation_links" => "navigation_links",
    "/videos" => "videos",
    "/pod" => "podcast_episodes_all",
    "/tags" => "tags"
  }.freeze

  CUTOVER_PATHS = %w[/async_info/navigation_links /tags /feed /feed.xml /rss].freeze

  def perform(path = "/")
    surrogate_key = SURROGATE_KEY_BY_PATH[path.to_s]
    if surrogate_key
      EdgeCache::PurgeByKey.call(surrogate_key, fallback_paths: path)
      EdgeCache::CutoverUrlBust.call(path) if CUTOVER_PATHS.include?(path.to_s)
    else
      EdgeCache::Bust.call(path)
    end
  end
end
