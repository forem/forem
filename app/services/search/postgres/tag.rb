module Search
  module Postgres
    class Tag
      def self.search_documents(term)
        # NOTE: this is added to be closer to the existing behavior of
        # Search::Tag which raises an exception for leading wildcards,
        # which in turn leads to no results.
        # Technically Postgres would returns results, `*java*` both returns `java`, and `javascript`
        return ::Tag.none.as_json if term.starts_with?("*")

        ::Tag
          .search_by_name(term)
          .where(supported: true)
          .select(:id, :name, :hotness_score, :rules_html, :supported, :short_summary)
          .as_json
      end
    end
  end
end
