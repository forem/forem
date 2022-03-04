module Podcasts
  class CreateEpisode
    def initialize(podcast_id, item)
      @podcast_id = podcast_id
      @item = item.is_a?(EpisodeRssItem) ? item : EpisodeRssItem.new(item)
    end

    def self.call(...)
      new(...).call
    end

    def call
      attributes = podcast_episode_attributes
      attributes = add_media_url(attributes)
      attributes = add_published_at(attributes)

      upsert_result = PodcastEpisode.upsert(
        attributes,
        unique_by: :index_podcast_episodes_on_media_url,
        returning: %i[id],
      )

      episode = PodcastEpisode.find(upsert_result.to_a.first["id"])

      finalize(episode)

      episode
    end

    private

    attr_reader :podcast_id, :item

    def podcast_episode_attributes
      now = Time.current

      {
        podcast_id: podcast_id,
        title: item.title,
        slug: item.title.parameterize,
        subtitle: item.itunes_subtitle,
        summary: item.itunes_summary,
        website_url: item.link,
        guid: item.guid,
        body: item.body,
        created_at: now,
        updated_at: now
      }
    end

    def add_media_url(attributes)
      return attributes if item.enclosure_url.blank?

      result = GetMediaUrl.call(item.enclosure_url)

      attributes.merge(
        reachable: result.reachable,
        media_url: result.url,
        https: result.https,
      )
    end

    def add_published_at(attributes)
      attributes.merge(published_at: item.pubDate.to_date)
    rescue ArgumentError, NoMethodError => e
      Rails.logger.error("not a valid date: #{e}")
      attributes
    end

    def finalize(episode)
      episode.purge_all
      episode.save if episode.processed_html.blank?
    end
  end
end
