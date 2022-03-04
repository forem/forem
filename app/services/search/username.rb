module Search
  class Username
    MAX_RESULTS = 6

    ATTRIBUTES = %i[
      id
      name
      profile_image
      username
    ].freeze

    def self.search_documents(term)
      results = ::User.search_by_name_and_username(term).limit(MAX_RESULTS).select(*ATTRIBUTES)

      serialize(results)
    end

    def self.serialize(results)
      Search::NestedUserSerializer
        .new(results, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
    private_class_method :serialize
  end
end
