module Search
  class PodcastEpisodeSerializer
    include FastJsonapi::ObjectSerializer

    attribute :id, &:search_id

    attributes :body_text, :class_name, :comments_count,
               :featured, :featured_number, :hotness_score, :path,
               :positive_reactions_count, :published, :published_at, :quote,
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
