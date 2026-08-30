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

    class Ineligible < Error
      def message
        I18n.t("services.authentication.authenticator.account_not_eligible")
      end
    end

    class AccountSwitchConfirmation < Error
      attr_reader :target_user

      def initialize(target_user)
        @target_user = target_user
        super("account_switch_confirmation")
      end
    end
  end
end
