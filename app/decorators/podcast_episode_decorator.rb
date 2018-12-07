class PodcastEpisodeDecorator < ApplicationDecorator
  delegate_all

  def comments_to_show_count
    cached_tag_list_array.include?("discuss") ? 75 : 25
  end

  def cached_tag_list_array
    (tag_list || "").split(", ")
  end
end
