module Podcasts
  class CreateEpisode
    def initialize(podcast_id, item)
      @podcast_id = podcast_id
      @item = item.is_a?(EpisodeRssItem) ? item : EpisodeRssItem.new(item)
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      ep = PodcastEpisode.new
      ep.title = item.title
      ep.podcast_id = podcast_id
      ep.slug = item.title.parameterize
      ep.subtitle = item.itunes_subtitle
      ep.summary = item.itunes_summary
      ep.website_url = item.link
      ep.guid = item.guid
      get_media_url(ep) if item.enclosure_url
      begin
        ep.published_at = item.pubDate.to_date
      rescue ArgumentError, NoMethodError => e
        Rails.logger.error("not a valid date: #{e}")
      end
      ep.body = item.body
      import_result = PodcastEpisode.import! [ep], on_duplicate_key_update: {
        conflict_target: %i[media_url],
        columns: %i[title slug subtitle summary website_url published_at reachable media_url https body]
      }
      episode = PodcastEpisode.find(import_result.ids.first)
      finalize(episode)
      episode
    end

    private

    attr_reader :podcast_id, :item

    def get_media_url(episode)
      result = GetMediaUrl.call(item.enclosure_url)
      episode.reachable = result.reachable
      episode.media_url = result.url
      episode.https = result.https
    end

    def finalize(episode)
      episode.purge_all
      episode.index_to_elasticsearch
    end
  end
end
