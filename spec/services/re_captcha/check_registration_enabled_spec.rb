require "rails_helper"

RSpec.describe ReCaptcha::CheckRegistrationEnabled, type: :request do
  describe "ReCaptcha for registration" do
    context "when recaptcha is enabled" do
      before do
        allow(SiteConfig).to receive(:require_captcha_for_email_password_registration).and_return(true)
      end

      it "is enabled if both site & secret keys present" do
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return("someSecretKey")
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("someSiteKey")
        expect(described_class.call).to be(true)
      end

      it "is disabled if site or secret key missing" do
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("")
        expect(described_class.call).to be(false)
      end
    end

    it "is disabled if recaptcha disabled for email signup" do
      allow(SiteConfig).to receive(:require_captcha_for_email_password_registration).and_return(false)
      expect(described_class.call).to be(false)
    end
  end
end
