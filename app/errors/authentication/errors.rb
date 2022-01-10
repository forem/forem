module Authentication
  module Errors
    class Error < StandardError
    end

    class ProviderNotFound < Error
    end

    class ProviderNotEnabled < Error
    end

    class PreviouslySuspended < Error
      def message
        I18n.t("errors.authentication.errors.suspended",
               community_name: Settings::Community.community_name,
               community_email: ForemInstance.email)
      end
    end

    # Raised when we find an email that's from a spammy domain.
    class SpammyEmailDomain < Error
    end
  end
end
