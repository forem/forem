module Search
  module Postgres
    class ReadingList
      DEFAULT_STATUSES = %w[valid confirmed].freeze

      def self.search_documents(user, term: nil, status: nil, page: 1, per_page: 60)
        status ||= DEFAULT_STATUSES
        page = (page || 1).to_i
        per_page = [(per_page || 60).to_i, 100].min

        reading_list_article_ids = user.reactions.readinglist.where(status: status)
          .order(created_at: :desc)
          .pluck(:reactable_id, :id)

        article_ids = reading_list_article_ids.map { |article_id, _reaction_id| article_id }
        articles = if term.present?
                     Search::Multisearch.call(term)
                       .includes(searchable: %i[user tags])
                       .where(searchable_type: "Article", searchable_id: article_ids)
                       .page(page)
                       .per(per_page)
                       .map(&:searchable)
                   else
                     Article.published.where(id: article_ids).page(page).per(per_page)
                   end

        articles = articles.index_by(&:id)

        result = Jbuilder.new do |json|
          json.reactions do
            json.array!(reading_list_article_ids) do |article_id, reaction_id|
              json.id reaction_id
              json.user_id user.id

              article = articles[article_id]
              json.reactable Search::ArticleSerializer.new(article).serializable_hash.dig(:data, :attributes).as_json
            end
          end

          json.total articles.length
        end

        result.attributes!
      end
    end
  end
end
