module DataSync
  module Elasticsearch
    class Article < Base
      RELATED_DOCS = %i[
        comments
      ].freeze

      SHARED_FIELDS = %i[
        published
        title
      ].freeze

      private

      def comments
        updated_record.comments
      end
    end
  end
end
