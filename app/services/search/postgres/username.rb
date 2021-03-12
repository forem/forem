module Search
  module Postgres
    class Username
      MAX_RESULTS = 6

      ATTRIBUTES = %i[
        id
        name
        profile_image
        username
      ].freeze

      def self.search_documents(term)
        users = search_users(term)

        users.map do |user|
          user.as_json(only: %i[id name username])
            .merge("profile_image_90" => user.profile_image_90)
        end
      end

      def self.search_users(term)
        ::User
          .search_by_username(term)
          .limit(MAX_RESULTS)
          .select(*ATTRIBUTES)
      end

      private_class_method :search_users
    end
  end
end
