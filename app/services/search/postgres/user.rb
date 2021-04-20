module Search
  module Postgres
    class User
      ATTRIBUTES = %i[id name profile_image username].freeze
      DEFAULT_PER_PAGE = 60
      MAX_PER_PAGE = 100

      def self.search_documents(term: nil, page: 0, per_page: DEFAULT_PER_PAGE)
        # NOTE: we should eventually update the frontend
        # to start from page 1
        page = page.to_i + 1
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

        relation = ::User.without_role(:suspended)

        relation = relation.search_users(term) if term.present?

        relation = relation.select(*ATTRIBUTES)
        # relation = relation.reorder()
        relation = relation.page(page).per(per_page)

        serialize(relation)
      end

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
