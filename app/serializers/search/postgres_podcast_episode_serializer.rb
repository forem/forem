module Search
  # TODO[@atsmith813]: Rename this to PodcastEpisodeSerializer once Elasticsearch is removed
  class PostgresPodcastEpisodeSerializer < ApplicationSerializer
    attribute :id, &:search_id

    attributes :body_text, :comments_count, :path, :published_at, :quote,
               :reactions_count, :subtitle, :summary, :title, :website_url

    attribute :class_name, -> { "PodcastEpisode" }
    attribute :highlight, -> { { body_text: [] } } # We don't display highlights in the UI for Podcasts
    attribute :hotness_score, -> { 0 }

    attribute :main_image do |podcast_episode|
      Images::Profile.call(podcast_episode.podcast.profile_image_url, length: 90)
    end

    attribute :podcast do |podcast_episode|
      podcast = podcast_episode.podcast

      {
        slug: podcast.slug,
        image_url: podcast.image_url,
        title: podcast.title
      }
    end

    attribute :public_reactions_count, -> { 0 }
    attribute :published, -> { true }
    attribute :search_score, -> { 0 }
    attribute :slug, &:podcast_slug
    attribute :user, -> { {} } # User data is not used in the UX for Podcasts
  end
end
