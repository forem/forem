module Search
  module Postgres
    class Tag
      def self.search_documents(term)
        ::Tag
          .search_by_name(term)
          .where(supported: true)
          .select(:id, :name, :hotness_score, :rules_html, :supported, :short_summary)
          .as_json
      end
    end
  end
end
