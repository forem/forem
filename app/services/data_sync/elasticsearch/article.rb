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

      delegate :comments, to: :@updated_record
    end
  end
end
