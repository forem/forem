module Authentication
  module Errors
    PREVIOUSLY_BANNED_MESSAGE = "It appears that your previous %<community_name>s " \
      "account was suspended. As such, we've taken measures to prevent you from " \
      "creating a new account with %<community_name>s and its community. If you " \
      "think that there has been a mistake, please email us at %<community_email>s, " \
      "and we will take another look.".freeze

    class Error < StandardError
    end

    class ProviderNotFound < Error
    end

    class ProviderNotEnabled < Error
    end

    class PreviouslyBanned < Error
      def message
        format(PREVIOUSLY_BANNED_MESSAGE,
               community_name: SiteConfig.community_name,
               community_email: SiteConfig.email_addresses[:contact])
      end
    end
  end
end
