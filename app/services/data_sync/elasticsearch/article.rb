module DataSync
  module Elasticsearch
    class Article
      RELATED_DOCS = %i[
        reactions
      ].freeze

      SHARED_ARTICLE_FIELDS = %i[
        body_markdown
        path
        published
        reading_time
        tag_list
        title
      ].freeze

      attr_accessor :article, :updated_fields

      def initialize(article, updated_fields)
        @article = article
        @updated_fields = updated_fields.deep_symbolize_keys
      end

      def call
        return unless sync_needed?

        RELATED_DOCS.each do |relation_name|
          if article.published
            send(relation_name).find_each(&:index_to_elasticsearch)
          elsif updated_fields.key?(:published)
            send(relation_name).find_each(&:remove_from_elasticsearch)
          end
        end
      end

      private

      def sync_needed?
        updated_fields.slice(*SHARED_ARTICLE_FIELDS).any? && reactions.any?
      end

      def reactions
        article.reactions.readinglist
      end
    end
  end
end
