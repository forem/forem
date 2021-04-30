module Search
  module Postgres
    class PodcastEpisode
      ATTRIBUTES = %w[
        body
        comments_count
        id
        podcast_id
        processed_html
        published_at
        quote
        reactions_count
        slug
        subtitle
        summary
        title
        website_url
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

        relation = ::PodcastEpisode
          .reachable
          .where(podcast_id: Podcast.published)
          .includes(:podcast)
          .references(:podcasts)
        relation = relation.search_podcast_episodes(term) if term.present?
        relation = relation.select(*ATTRIBUTES)
        relation = sort(relation, sort_by, sort_direction)
        results = relation.page(page).per(per_page)

        serialize(results)
      end

      def self.sort(relation, sort_by, sort_direction)
        return relation.reorder(sort_by => sort_direction) if sort_by && sort_direction

        relation.reorder(nil)
      end
      private_class_method :sort

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
