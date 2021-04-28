module Search
  module Postgres
    class PodcastEpisode
      ATTRIBUTES = [
        "podcasts.id",
        "podcasts.image",
        "podcasts.published",
        "podcasts.slug",
        "podcasts.title",
        "podcast_episodes.body",
        "podcast_episodes.comments_count",
        "podcast_episodes.id",
        "podcast_episodes.podcast_id",
        "podcast_episodes.processed_html",
        "podcast_episodes.published_at",
        "podcast_episodes.quote",
        "podcast_episodes.reactions_count",
        "podcast_episodes.subtitle",
        "podcast_episodes.summary",
        "podcast_episodes.title",
        "podcast_episodes.website_url",
      ].freeze
      private_constant :ATTRIBUTES

      DEFAULT_PER_PAGE = 60
      private_constant :DEFAULT_PER_PAGE

      MAX_PER_PAGE = 120 # to avoid querying too many items, we set a maximum amount for a page
      private_constant :MAX_PER_PAGE

      def self.search_documents(page: 0, per_page: DEFAULT_PER_PAGE, sort_by: nil, sort_direction: nil, term: nil)
        # NOTE: [@rhymes/atsmith813] we should eventually update the frontend
        # to start from page 1
        page = page.to_i + 1
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

        relation = ::PodcastEpisode.includes(:podcast).available
        relation = relation.search_podcast_episodes(term) if term.present?
        relation = relation.select(*ATTRIBUTES)
        relation = relation.reorder(sort_by => sort_direction) if sort_by && sort_direction

        results = relation.page(page).per(per_page)

        serialize(results)
      end

      def self.serialize(results)
        Search::PostgresPodcastEpisodeSerializer
          .new(results, is_collection: true)
          .serializable_hash[:data]
          .pluck(:attributes)
      end
      private_class_method :serialize
    end
  end
end
