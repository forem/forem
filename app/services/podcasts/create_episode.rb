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
      get_media_url(ep)
      begin
        ep.published_at = item.pubDate.to_date
      rescue StandardError => e
        Rails.logger.error("not a valid date: #{e}")
      end
      ep.body = item.body
      ep.save!
      ep
    end

    private

    attr_reader :podcast_id, :item

    # checking url when it is https is useless, the url is set to the enclosure url anyway
    def get_media_url(episode)
      episode.media_url = if HTTParty.head(item.enclosure_url.gsub(/http:/, "https:")).code == 200
                            item.enclosure_url.gsub(/http:/, "https:")
                          else
                            item.enclosure_url
                          end
    rescue StandardError
      # podcast episode must have a media_url
      episode.media_url = item.enclosure_url
      episode.podcast.update(status_notice: I18n.t(:unplayable, scope: "podcasts.statuses")) if episode.podcast.status_notice.empty?
    end
  end
end
