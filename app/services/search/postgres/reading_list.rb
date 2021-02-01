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
                     full_text_search(
                       term, article_ids, tags: tags, tagged_with_any: tagged_with_any, page: page, per_page: per_page
                     )
                   else
                     # TODO: [@rhymes] use .select() to avoid loading unnecessary fields
                     relation = Article.published.where(id: article_ids)
                     relation = relation.tagged_with(tags, any: tagged_with_any) if tags.present?
                     relation.page(page).per(per_page)
                   end

        serialize_articles(user, articles.index_by(&:id), reading_list_article_ids)
      end

      def self.full_text_search(term, article_ids, tags:, tagged_with_any:, page:, per_page:)
        # NOTE: [@rhymes] I'm not sure how to combine `pg_search`'s multisearch
        # with the `.tagged_with()` scope. I could hack it by manually filtering articles based on their
        # `cached_tag_list` but then we'd break pagination, as the filtering needs to happen before
        # results are split in pages
        relation = Search::Multisearch.call(term)
          .with_pg_search_highlight
          .with_pg_search_rank
          .includes(searchable: %i[user tags])
          .where(searchable_type: "Article", searchable_id: article_ids)

        # NOTE: acts-as-taggable-on generates SQL at runtime to join `taggings`, `tags` and `articles`
        # we can't directly attach it to `PgSearch::Document` as we're indeed trying to filter articles whose
        # tags appear in the list. For this implementation I decided to do a 2-step algorithm: search and filter.
        # Rather than trying to build a monster SQL query that joins `pg_search_documents`, `taggings`, `tags` and
        # `articles` (it can be done manually but we kinda lose acts-as-taggable-on dynamic features) I decided to
        # re-use `ActsAsTaggableOn::Taggable::TaggedWithQuery` to filter on articles that have previously matched
        # by the FTS search.
        # Keeping in mind that we're searching inside a reading list (a subset of saved articles), this should be fast
        # enough.
        if tags.present?
          # `tagged_with` returns article objects, we tell it to find tagged articles within those returned
          # by the search
          relation = tagged_with(relation.map(&:searchable_id), tags, tagged_with_any)
          relation.page(page).per(per_page)

          # NOTE: commented this out for now as it's only needed if we actually want to match
          # `pg_search_highlight`/`pg_search_highlight` with the results, but they aren't currently used

          # filtered_articles = tagged_articles.map do |article|
          #   doc = search_documents[article.id]
          #   next unless doc

          #   article.search_highlight = doc.pg_search_highlight
          #   article.search_rank = doc.pg_search_rank
          #   article
          # end

          # Kaminari.paginate_array(filtered_articles).page(page).per(per_page)
        else
          relation = relation.page(page).per(per_page)

          # extract Article objects from `PgSearch::Document` objects
          relation.map do |doc|
            article = doc.searchable
            article.search_highlight = doc.pg_search_highlight
            article.search_rank = doc.pg_search_rank
            article
          end
        end
      end
      private_class_method :full_text_search

      # borrowed from https://github.com/mbleigh/acts-as-taggable-on/blob/47da5036dea61cb971bfaf72de5fa93c85255307/lib/acts_as_taggable_on/taggable/core.rb#L110
      def self.tagged_with(article_ids, tags, tagged_with_any)
        tag_list = ActsAsTaggableOn.default_parser.new(tags).parse
        return Article.none if tag_list.empty?

        relation = ActsAsTaggableOn::Taggable::TaggedWithQuery.build(
          Article,
          ActsAsTaggableOn::Tag,
          ActsAsTaggableOn::Tagging,
          tag_list,
          any: tagged_with_any,
        )

        relation.where(id: article_ids)
      end
      private_class_method :tagged_with

      def self.serialize_articles(user, articles, reading_list_article_ids)
        # rubocop:disable Metrics/BlockLength
        # see Search::FeedContent::parse_doc
        Jbuilder.new do |json|
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
        end.attributes!
        # rubocop:enable Metrics/BlockLength
      end
      private_class_method :serialize_articles
    end
  end
end
