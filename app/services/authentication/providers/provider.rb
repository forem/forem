module Authentication
  module Providers
    # Authentication provider
    class Provider
      # name of the field to store the upstream identity's creation date in
      CREATED_AT_FIELD = "".freeze
      # name of the field to store the upstream identity's username in
      USERNAME_FIELD = "".freeze

      def initialize(auth_payload)
        @auth_payload = cleanup_payload(auth_payload.dup)
        @info = auth_payload.info
        @raw_info = auth_payload.extra.raw_info
      end

      # Extract data for a brand new user
      def new_user_data
        raise SubclassResponsibility
      end

      # Extract data for an existing user
      def existing_user_data
        raise SubclassResponsibility
      end

      def name
        auth_payload.provider
      end

      def payload
        auth_payload
      end

      def user_created_at_field
        self.class::CREATED_AT_FIELD
      end

      def user_username_field
        self.class::USERNAME_FIELD
      end

      def user_email
        info.email
      end

      def user_nickname
        info.nickname
      end

      protected

      # Remove sensible data from the payload
      def cleanup_payload(_auth_payload)
        raise SubclassResponsibility
      end

      attr_reader :auth_payload, :info, :raw_info
    end
  end
end
