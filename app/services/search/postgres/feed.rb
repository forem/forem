module Search
  module Postgres
    class Feed
      FIELDS_TO_EXCLUDE_FROM_SERIALIZATION = %i[
        approved body_text experience_level_rating
        experience_level_rating_distribution featured featured_number
        hotness_score language published reactions_count score
      ].freeze

      def self.search_documents(term: nil, page: 1, per_page: 60)
        page = (page || 1).to_i
        per_page = [(per_page || 60).to_i, 100].min

        relation = if term.present?
                     Search::Multisearch.call(term)
                       .with_pg_search_highlight
                       .with_pg_search_rank
                       .includes(searchable: %i[user tags])
                   else
                     PgSearch::Document.none
                   end

        relation.page(page).per(per_page).map do |doc|
          searchable = doc.searchable
          serializer = ::Search.const_get("#{searchable.class}Serializer")
          attributes = serializer.new(searchable).serializable_hash.dig(:data, :attributes)
          prepare_doc(doc, attributes).as_json
        end
      end

      # borrowed from Search::FeedContent.prepare_doc
      def self.prepare_doc(doc, attributes)
        attributes[:_score] = doc.pg_search_rank
        attributes[:id] = attributes[:id].split("_").last.to_i
        attributes[:tag_list] = attributes[:tags]&.map { |t| t[:name] } || []
        attributes[:flare_tag] = attributes[:flare_tag_hash]
        attributes[:user_id] = attributes.dig(:user, :id)
        attributes[:highlight] = doc.pg_search_highlight
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
    end
  end
end
