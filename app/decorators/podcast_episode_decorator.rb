class PodcastEpisodeDecorator < ApplicationDecorator
  # this method exists because podcast episodes are "commentables"
  # and in some parts of the code we assume they have this method,
  # but podcast episodes don't have a cached_tag_list like articles do
  def cached_tag_list_array
    tag_list
  end

  def readable_publish_date
    return "" unless published_at

    if published_at.year == Time.current.year
      I18n.l(published_at, format: :short)
    else
      I18n.l(published_at, format: :short_with_yy)
    end
  end

  def published_timestamp
    return "" unless published_at

    published_at.utc.iso8601
  end

  def mobile_player_metadata
    {
      podcastName: podcast.title,
      episodeName: title,
      podcastImageUrl: Images::Optimizer.call(podcast.image_url, width: 600, quality: 80)
    }
  end

  def published_at_int
    published_at.to_i
  end
end
