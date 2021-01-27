module Search
  module Postgres
    class ReadingList
      DEFAULT_STATUSES = %w[valid confirmed].freeze

      def self.search_documents(user, term: nil, status: nil, tags: nil, tags_mode: :any, page: 1, per_page: 60)
        status ||= DEFAULT_STATUSES
        page = (page || 1).to_i
        per_page = [(per_page || 60).to_i, 100].min
        tagged_with_any = tags_mode.to_sym == :any

        reading_list_article_ids = user.reactions.readinglist.where(status: status)
          .order(created_at: :desc)
          .pluck(:reactable_id, :id)

        article_ids = reading_list_article_ids.map { |article_id, _reaction_id| article_id }

        articles = if term.present?
                     # NOTE: [@rhymes] I'm not sure how to combine `pg_search`'s multisearch
                     # with the `.tagged_with()` scope. I could hack it by manually filtering articles based on their
                     # `cached_tag_list` but then we'd break pagination, as the filtering needs to happen before
                     # results are split in pages
                     results = Search::Multisearch.call(term)
                       .with_pg_search_highlight
                       .with_pg_search_rank
                       .includes(searchable: %i[user tags])
                       .where(searchable_type: "Article", searchable_id: article_ids)
                       .page(page)
                       .per(per_page)

                     results.map do |doc|
                       article = doc.searchable
                       article.search_highlight = doc.pg_search_highlight
                       article.search_rank = doc.pg_search_rank
                       article
                     end
                   else
                     # TODO: [@rhymes] use .select() to avoid loading unnecessary fields
                     relation = Article.published.where(id: article_ids)
                     relation = relation.tagged_with(tags, any: tagged_with_any) if tags
                     relation.page(page).per(per_page)
                   end

        articles = articles.index_by(&:id)

        # rubocop:disable Metrics/BlockLength
        # see Search::FeedContent::parse_doc
        result = Jbuilder.new do |json|
          json.reactions do
            json.array!(reading_list_article_ids) do |article_id, reaction_id|
              article = articles[article_id]
              next unless article

              json.id reaction_id
              json.user_id user.id

              sa = Search::ArticleSerializer.new(article).serializable_hash
                .dig(:data, :attributes)
                .as_json
                .except(
                  *%w[
                    approved body_text experience_level_rating
                    experience_level_rating_distribution featured
                    featured_number hotness_score language published
                    reactions_count score
                  ],
                )

              published_at_timestamp = Time.zone.parse(sa["published_at"] || "")
              sa.merge!({
                          "_score" => article.search_rank,
                          "id" => sa["id"].split("_").last.to_i,
                          "flare_tag" => sa["flare_tag_hash"],
                          "highlight" => article.search_highlight,
                          "podcast" => { # unsure why we need this, see Search::FeedContent::parse_doc
                            "slug" => sa["slug"],
                            "image_url" => sa["main_image"],
                            "title" => sa["title"]
                          },
                          "published_at_int" => published_at_timestamp.to_i,
                          "published_timestamp" => sa["published_at"],
                          "readable_publish_date" => sa["readable_publish_date_string"],
                          "tag_list" => (sa["tags"]&.map { |t| t["name"] } || []),
                          "user_id" => sa.dig("user", "id")
                        })

              json.reactable sa
            end
          end

          json.total articles.length
        end
        # rubocop:enable Metrics/BlockLength

        result.attributes!
      end
    end
  end
end
