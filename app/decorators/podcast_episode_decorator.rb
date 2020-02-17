class PodcastEpisodeDecorator < ApplicationDecorator
  delegate_all

  def comments_to_show_count
    cached_tag_list_array.include?("discuss") ? 75 : 25
  end

  def cached_tag_list_array
    (tag_list || "").split(", ")
  end

  def readable_publish_date
    return unless published_at

    if published_at.year == Time.current.year
      published_at.strftime("%b %e")
    else
      published_at.strftime("%b %e '%y")
    end
  end

  def published_timestamp
    published_at&.utc&.iso8601
  end
end
