module Search
  module Postgres
    class Username
      ATTRIBUTES = %i[
        id
        name
        profile_image
        username
      ].freeze

      def self.search_documents(term)
        users = search_users(term)

        # We need to re-map profile_image as the profile_image_90 method on the
        # User model
        users.map do |user|
          {
            id: user.id,
            name: user.name,
            profile_image_90: user.profile_image_90,
            username: user.username
          }
        end.as_json
      end

      def self.search_users(term)
        ::User
          .search_by_username(term)
          .select(*ATTRIBUTES)
      end
    end
  end
end
