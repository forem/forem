json.array! @podcast_episodes do |episode|
  json.type_of      "podcast_episodes"
  json.class_name   "PodcastEpisode"

  json.extract!(episode, :id, :path, :title)

  json.image_url episode.image_url || episode.podcast.image_url

  json.podcast do
    json.extract!(episode.podcast, :title, :slug, :image_url)
  end
end
