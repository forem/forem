require "rss"
require "rss/itunes"

class PodcastFeed
  def get_all_episodes
    Podcast.find_each do |podcast|
      get_episodes(podcast)
    end
  end

  def get_episodes(podcast, num = 1000)
    rss = HTTParty.get(podcast.feed_url).body
    feed = RSS::Parser.parse(rss, false)
    feed.items.first(num).each do |item|
      if !existing_episode(item, podcast)
        create_new_episode(item, podcast)
      elsif ep = existing_episode(item, podcast).first
        update_existing_episode(ep, item, podcast)
      end
    end
    feed.items.size
  rescue StandardError => e
    puts e.message
  end

  def create_new_episode(item, podcast)
    ep = PodcastEpisode.new
    ep.title = item.title
    ep.podcast_id = podcast.id
    ep.slug = item.title.downcase.gsub(/[^0-9a-z ]/i, "").gsub(" ", "-")
    ep.subtitle = item.itunes_subtitle
    ep.summary = item.itunes_summary
    ep.website_url = item.link
    ep.guid = item.guid
    get_media_url(ep, item, podcast)
    begin
      ep.published_at = item.pubDate.to_date
    rescue StandardError
      puts "not valid date"
    end
    ep.body = item.content_encoded || item.itunes_summary || item.description
    ep.save!
  end

  def update_existing_episode(episode, item, _podcast)
    if episode.published_at == nil
      begin
        episode.published_at = item.pubDate.to_date
        episode.save
      rescue StandardError
        puts "not valid date"
      end
    end
    update_media_url(episode, item)
  end

  def existing_episode(item, podcast)
    # presence returns nil if the query is an empty array, otherwise returns the array
    PodcastEpisode.where(media_url: item.enclosure.url).presence ||
      PodcastEpisode.where(title: item.title).presence ||
      PodcastEpisode.where(guid: item.guid.to_s).presence ||
      (podcast.unique_website_url? && PodcastEpisode.where(website_url: item.link).presence)
  end

  def get_media_url(episode, item, podcast)
    episode.media_url = if Rails.env.test? ||
        HTTParty.head(item.enclosure.url.gsub(/http:/, "https:")).code == 200
                          item.enclosure.url.gsub(/http:/, "https:")
                        else
                          item.enclosure.url
                        end
  rescue StandardError
    # podcast episode must have a media_url
    episode.media_url = item.enclosure.url
    if podcast.status_notice.empty?
      podcast.update(status_notice: "This podcast may not be playable in the browser")
    end
  end

  def update_media_url(episode, item)
    if episode.media_url.include?("https")
      nil
    elsif !episode.media_url.include?("https") &&
        item.enclosure.url.include?("https")
      episode.update!(media_url: item.enclosure.url)
    end
  rescue StandardError
    message = "something went wrong with #{podcast.title}, #{episode.title} -- #{episode.media_url}"
    logger.info message
  end
end
