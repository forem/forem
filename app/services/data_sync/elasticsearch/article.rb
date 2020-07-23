module DataSync
  module Elasticsearch
    class Article < Base
      RELATED_DOCS = %i[
        reactions
      ].freeze

      SHARED_FIELDS = %i[
        body_markdown
        path
        published
        reading_time
        tag_list
        title
      ].freeze

      private

      def sync_related_documents
        RELATED_DOCS.each do |relation_name|
          if updated_record.published
            __send__(relation_name).find_each(&:index_to_elasticsearch)
          elsif updated_fields.key?(:published)
            __send__(relation_name).find_each(&:remove_from_elasticsearch)
          end
        end
      end

      def sync_needed?
        updated_fields.slice(*SHARED_FIELDS).any? && reactions.any?
      end

      def reactions
        updated_record.reactions.readinglist
      end
    end
  end
end
