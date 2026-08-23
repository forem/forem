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

    # Raised when an incoming OAuth identity resolves to a suspended or
    # spam-flagged account: authentication fails closed and the identity
    # never attaches to anyone.
    class Ineligible < Error
      def message
        I18n.t("services.authentication.authenticator.account_not_eligible")
      end
    end

    # Raised when a signed-in user completes OAuth for a provider+uid that
    # resolves to a different, eligible existing account. The callback
    # controller renders a confirmation interstitial instead of silently
    # attaching the identity; carrying the resolved target avoids resolving
    # it twice.
    class AccountSwitchConfirmation < Error
      attr_reader :target_user

      def initialize(target_user)
        @target_user = target_user
        super("account_switch_confirmation")
      end
    end
  end
end
