module Authentication
  module Providers
    # Authentication provider
    class Provider
      delegate :email, to: :info, prefix: :user
      delegate :user_username_field, to: :class

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

      def user_nickname
        info.nickname.to_s
      end

      def name
        auth_payload.provider
      end

      def payload
        auth_payload
      end

      def self.provider_name
        name.demodulize.downcase.to_sym
      end

      def self.user_username_field
        "#{provider_name}_username".to_sym
      end

      def self.official_name
        name.demodulize
      end

      def self.settings_url
        raise SubclassResponsibility
      end

      def self.authentication_path(**kwargs)
        ::Authentication::Paths.authentication_path(provider_name, **kwargs)
      end

      def self.sign_in_path(**_kwargs)
        raise SubclassResponsibility
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
