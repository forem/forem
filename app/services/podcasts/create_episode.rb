module Podcasts
  class CreateEpisode
    def initialize(podcast, item)
      @podcast = podcast
      @item = item
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      ep = PodcastEpisode.new
      ep.title = item.title
      ep.podcast_id = podcast.id
      ep.slug = item.title.parameterize
      ep.subtitle = item.itunes_subtitle
      ep.summary = item.itunes_summary
      ep.website_url = item.link
      ep.guid = item.guid
      get_media_url(ep, item, podcast)
      begin
        ep.published_at = item.pubDate.to_date
      rescue StandardError => e
        Rails.logger.error("not a valid date: #{e}")
      end
      ep.body = item.content_encoded || item.itunes_summary || item.description
      ep.save!
      ep
    end

    private

    attr_reader :podcast, :item

    # checking url when it is https is useless, the url is set to the enclosure url anyway
    def get_media_url(episode, item, podcast)
      episode.media_url = if HTTParty.head(item.enclosure.url.gsub(/http:/, "https:")).code == 200
                            item.enclosure.url.gsub(/http:/, "https:")
                          else
                            item.enclosure.url
                          end
    rescue StandardError
      # podcast episode must have a media_url
      episode.media_url = item.enclosure.url
      podcast.update(status_notice: "This podcast may not be playable in the browser") if podcast.status_notice.empty?
    end
  end
end
