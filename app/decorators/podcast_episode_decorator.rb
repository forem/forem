class PodcastEpisodeDecorator < ApplicationDecorator
  delegate_all

  def comments_to_show_count
    cached_tag_list_array.include?("discuss") ? 75 : 25
  end

  def cached_tag_list_array
    (tag_list || "").split(", ")
  end

  def readable_publish_date
    published_at&.strftime("%b %e")
  end

  def published_timestamp
    published_at&.utc&.iso8601
  end
end
