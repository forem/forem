module Search
  class PodcastEpisodeSerializer < ApplicationSerializer
    attribute :id, &:search_id

    attributes :body_text, :class_name, :comments_count, :hotness_score, :path,
               :public_reactions_count, :published, :published_at, :quote,
               :reactions_count, :search_score, :subtitle, :summary, :title,
               :website_url

    attribute :main_image do |pde|
      ProfileImage.new(pde.podcast).get(width: 90)
    end
    attribute :slug, &:podcast_slug

    attribute :tags do |pde|
      pde.tags.map do |tag|
        { name: tag.name, keywords_for_search: tag.keywords_for_search }
      end
    end

    attribute :user do |pde|
      NestedUserSerializer.new(pde.podcast.creator).serializable_hash.dig(
        :data, :attributes
      )
    end
  end
end
