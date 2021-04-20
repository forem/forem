module Search
  module Postgres
    class User
      ATTRIBUTES = %i[
        id
        name
        profile_image
        username
      ].freeze

      DEFAULT_PER_PAGE = 60
      MAX_PER_PAGE = 100

      # User.search_sore used to take employer related fields into account, but they have since been moved to profile
      # and removed from fields that are searched against.
      HOTNESS_SCORE_ORDER = Arel.sql(%{
        (((articles_count + comments_count + reactions_count + badge_achievements_count) * 10) * reputation_modifier)
        DESC
      }.squish).freeze

      def self.search_documents(term: nil, sort_by: :nil, sort_direction: :desc, page: 0, per_page: DEFAULT_PER_PAGE)
        # NOTE: we should eventually update the frontend
        # to start from page 1
        page = page.to_i + 1
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

        relation = ::User.without_role(:suspended)

        relation = relation.search_users(term) if term.present?

        relation = relation.select(*ATTRIBUTES)

        relation = sort(relation, sort_by, sort_direction)

        relation = relation.page(page).per(per_page)

        serialize(relation)
      end

      def self.sort(relation, sort_by, sort_direction)
        return relation.reorder(sort_by => sort_direction) if sort_by&.to_sym == :created_at

        relation.reorder(HOTNESS_SCORE_ORDER)
      end
      private_class_method :sort

      def self.serialize(users)
        Search::PostgresUserSerializer
          .new(users, is_collection: true)
          .serializable_hash[:data]
          .pluck(:attributes)
      end
      private_class_method :serialize
    end
  end
end
