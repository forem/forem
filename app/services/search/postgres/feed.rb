module Search
  module Postgres
    class Feed
      FIELDS_TO_EXCLUDE_FROM_SERIALIZATION = %i[
        approved body_text experience_level_rating
        experience_level_rating_distribution featured featured_number
        hotness_score language published reactions_count score
      ].freeze

      def self.search_documents(
        term: nil, approved: nil, class_name: nil, id: nil, sort_by: nil, sort_direction: nil, published_at: nil,
        page: 1, per_page: 60
      )
        page = (page || 1).to_i + 1 # NOTE: the frontend starts at 0, need to fix this
        per_page = [(per_page || 60).to_i, 100].min

        relation = if term.present?
                     relation = Search::Multisearch.call(term)
                       .with_pg_search_highlight
                       .with_pg_search_rank
                       .includes(
                         searchable: [
                           {  podcast_episode: {  podcast: :creator } },
                           { articles: :organization },
                           :tag_taggings, :tags, :comments
                         ],
                       )

                     relation = select_approved_articles(relation, approved, class_name)
                     relation = relation.where(searchable_type: class_name) if class_name.present?
                     relation.where(searchable_id: id) if id.present?
                   else
                     relation = PgSearch::Document
                     relation = relation.where(searchable_type: class_name) if class_name.present?
                     select_articles_by_publication_date(relation, published_at, class_name)
                   end

        relation = sort_documents(relation, sort_by, sort_direction)

        relation.page(page).per(per_page).map do |doc|
          searchable = doc.searchable
          serializer = ::Search.const_get("#{searchable.class}Serializer")
          attributes = serializer.new(searchable).serializable_hash.dig(:data, :attributes)
          prepare_doc(doc, attributes).as_json
        end
      end

      # borrowed from Search::FeedContent.prepare_doc
      def self.prepare_doc(doc, attributes)
        attributes[:_score] = doc.respond_to?(:pg_search_rank) ? doc.pg_search_rank : 0
        attributes[:id] = attributes[:id].split("_").last.to_i
        attributes[:tag_list] = attributes[:tags]&.map { |t| t[:name] } || []
        attributes[:flare_tag] = attributes[:flare_tag_hash]
        attributes[:user_id] = attributes.dig(:user, :id)

        if doc.respond_to?(:pg_search_highlight)
          attributes[:highlight] = { body_text: [doc.pg_search_highlight] } # format expected by the JS frontend
        end

        attributes[:readable_publish_date] = attributes[:readable_publish_date_string]
        attributes[:podcast] = {
          slug: attributes[:slug],
          image_url: attributes[:main_image],
          title: attributes[:title]
        }
        attributes[:published_at_int] = attributes[:published_at].to_i
        attributes[:published_timestamp] = attributes[:published_at].rfc3339

        attributes.except(*FIELDS_TO_EXCLUDE_FROM_SERIALIZATION)
      end
      private_class_method :prepare_doc

      def self.select_approved_articles(relation, approved, class_name)
        return relation unless approved || (class_name && class_name != "Article")

        relation
          .joins("INNER JOIN articles ON articles.id = pg_search_documents.searchable_id")
          .where(searchable_type: "Article")
          .where(articles: { approved: approved })
      end
      private_class_method :select_approved_articles

      def self.select_articles_by_publication_date(relation, published_at, class_name)
        return relation unless published_at.present? || (class_name && class_name != "Article")

        if published_at[:gte].present?
          relation.where(published_at: published_at[:gte]..)
        elsif published_at[:lte].present?
          relation.where(published_at: ..published_at[:gte])
        else
          relation
        end
      end
      private_class_method :select_articles_by_publication_date

      def self.sort_documents(relation, sort_by, sort_direction)
        return relation unless sort_by.present? && sort_direction.present?

        relation.reorder(sort_by => sort_direction)
      end
    end
  end
end
