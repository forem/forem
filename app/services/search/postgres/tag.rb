module Search
  module Postgres
    class Tag
      ATTRIBUTES = %i[id name hotness_score rules_html supported short_summary].freeze

      def self.search_documents(term)
        ::Tag
          .search_by_name(term)
          .where(supported: true)
          .reorder(hotness_score: :desc)
          .select(*ATTRIBUTES)
          .as_json
      end
    end
  end
end
