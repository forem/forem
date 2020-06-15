module Warden
  module Test
    module Helpers
      # Override Warden Test Helper login and logout methods with on_request
      # instead of on_next_request in order to prevent the race condition where
      # we make a request before the user is finished authenticating
      # https://github.com/wardencommunity/warden/blob/a317fde34a6f804bc24efee4bbbe38c76f4cf71e/lib/warden/test/helpers.rb#L19
      def login_as(user, opts = {})
        Warden::Manager.on_request do |proxy|
          opts[:event] || :authentication
          proxy.set_user(user, opts)
        end
      end

      def logout(*scopes)
        Warden::Manager.on_request do |proxy|
          proxy.logout(*scopes)
        end
      end
    end
  end
end
