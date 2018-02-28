json.array! @podcast_episodes do |episode|
  json.type_of            "podcast_episodes"
  json.id                 episode.id
  json.path               episode.path
  json.image_url          episode.image_url || episode.podcast.image_url
  json.title              episode.title
  json.podcast do
    json.title            episode.podcast.title
    json.slug             episode.podcast.slug
    json.image_url        episode.podcast.image_url
  end
end
