module DataSync
  module Elasticsearch
    class Organization < Base
      RELATED_DOCS = %i[
        articles
      ].freeze

      SHARED_FIELDS = %i[
        slug
        name
        profile_image
      ].freeze

      delegate :articles, to: :@updated_record
    end
  end
end
