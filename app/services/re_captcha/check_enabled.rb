# This service encapsulates the logic related to validating if reCAPTCHA is
# enabled in the current Forem instance. The decision is based on making
# sure the necessary SiteConfig keys are available and also on the user
# object passed in.
#
# Example use: ReCaptcha::CheckEnabled.call(current_user) => true/false
module ReCaptcha
  class CheckEnabled
    def self.call(current_user = nil)
      new(current_user).call
    end

    def initialize(current_user)
      @current_user = current_user
    end

    def call
      # recaptcha will not be enabled if site key and secret key aren't set
      return false unless keys_configured?
      # recaptcha will always be enabled when not logged in
      return true if @current_user.nil?
      # recaptcha will not be enabled for trusted/admin/tag mod users
      return false if @current_user.auditable?
      # recaptcha will be enabled if the user has been banned
      return true if @current_user.banned

      # recaptcha will be enabled if the user has a vomit or is too recent
      @current_user.vomitted_on? || @current_user.created_at > 1.month.ago
    end

    private

    def keys_configured?
      SiteConfig.recaptcha_site_key.present? && SiteConfig.recaptcha_secret_key.present?
    end
  end
end
