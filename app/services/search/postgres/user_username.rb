module Search
  module Postgres
    class UserUsername
      def self.search_documents(term, page: 1, per_page: 20)
        # NOTE: this is added to be closer to the existing behavior of
        # Search::User which raises an exception for leading wildcards,
        # which in turn leads to no results.
        return ::User.none.as_json if term.starts_with?("*")

        page = (page || 1).to_i
        per_page = (per_page || 30).to_i

        ::User
          .search_by_username(term)
          .select(:username)
          .page(page)
          .per(per_page)
          .pluck(:username)
      end
    end
  end
end
