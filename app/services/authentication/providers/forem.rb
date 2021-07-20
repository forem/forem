module Authentication
  module Providers
    # GitHub authentication provider, uses omniauth-github as backend
    class Forem < Provider
      OFFICIAL_NAME = "Forem".freeze
      SETTINGS_URL = "https://passport.forem.com/oauth/authorized_applications".freeze

      def new_user_data
        # name = raw_info.name.presence || info.name
        # p "new user data"
        # p name
        {
          email: "ben@forem.com",
          name: "name",
          remote_profile_image_url: "https://res.cloudinary.com/hkyugldxm/image/fetch/s--SVXRShhn--/c_limit,f_png,fl_progressive,q_80,w_512/https://thismmalife-images.s3.amazonaws.com/i/c6aakaen9bmk70qaduy9.png",
          forem_username: "ben#{rand(100000)}"
        }
      end

      def existing_user_data
        {}
      end

      def self.official_name
        OFFICIAL_NAME
      end

      def self.settings_url
        SETTINGS_URL
      end

      def self.sign_in_path(**kwargs)
        ::Authentication::Paths.sign_in_path(
          provider_name,
          **kwargs,
        )
      end

      protected

      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
