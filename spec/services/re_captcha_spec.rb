require "rails_helper"

RSpec.describe "ReCaptcha", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:recent_user) { create(:user) }
  let(:older_user) { create(:user, created_at: 3.months.ago) }
  let(:trusted_user) { create(:user, :trusted) }
  let(:vomitted_user) do
    user = create(:user, created_at: 3.months.ago)
    create(:vomit_reaction, category: "vomit", reactable: user, user: trusted_user, status: "confirmed")
    user
  end

  describe "ReCaptcha for registration" do
    context "when recaptcha is enabled" do
      before do
        allow(SiteConfig).to receive(:require_captcha_for_email_password_registration).and_return(true)
      end

      it "is enabled if both site & secret keys present" do
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return("someSecretKey")
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("someSiteKey")

        expect(ReCaptcha.for_registration_enabled?).to be(true)
        expect(ReCaptcha.for_registration_disabled?).to be(false)
      end

      it "is disabled if site or secret key missing" do
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("")

        expect(ReCaptcha.for_registration_enabled?).to be(false)
        expect(ReCaptcha.for_registration_disabled?).to be(true)
      end
    end

    it "is disabled if recaptcha disabled for email signup" do
      allow(SiteConfig).to receive(:require_captcha_for_email_password_registration).and_return(false)

      expect(ReCaptcha.for_registration_enabled?).to be(false)
      expect(ReCaptcha.for_registration_disabled?).to be(true)
    end
  end

  describe "ReCaptcha for user actions like Abuse Reports (FeedbackMessages)" do
    context "when recaptcha keys are not configured" do
      before do
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return(nil)
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return(nil)
      end

      it "marks ReCaptcha as enabled" do
        expect(ReCaptcha.call.enabled?).to be(false)
        expect(ReCaptcha.call.disabled?).to be(true)
      end
    end

    context "when recaptcha keys are configured" do
      before do
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("stub")
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return("stub")
        allow(SiteConfig).to receive(:require_captcha_for_email_password_registration).and_return(true)
      end

      it "marks ReCaptcha as enabled when logged out" do
        expect(ReCaptcha.call.enabled?).to be(true)
        expect(ReCaptcha.call.disabled?).to be(false)
      end

      it "marks ReCaptcha as disabled when older user is logged in" do
        sign_in older_user
        expect(ReCaptcha.call(older_user).enabled?).to be(false)
        expect(ReCaptcha.call(older_user).disabled?).to be(true)
      end

      it "marks ReCaptcha as disabled when admin is logged in" do
        sign_in admin
        expect(ReCaptcha.call(admin).enabled?).to be(false)
        expect(ReCaptcha.call(admin).disabled?).to be(true)
      end

      it "marks ReCaptcha as disabled when trusted user is logged in" do
        sign_in trusted_user
        expect(ReCaptcha.call(trusted_user).enabled?).to be(false)
        expect(ReCaptcha.call(trusted_user).disabled?).to be(true)
      end

      it "marks ReCaptcha as enabled when user with vomits is logged in" do
        sign_in vomitted_user
        expect(ReCaptcha.call(vomitted_user).enabled?).to be(true)
        expect(ReCaptcha.call(vomitted_user).disabled?).to be(false)
      end

      it "marks ReCaptcha as enabled when a banned user is logged in" do
        older_user.add_role(:banned)
        sign_in older_user
        expect(ReCaptcha.call(older_user).enabled?).to be(true)
        expect(ReCaptcha.call(older_user).disabled?).to be(false)
        older_user.remove_role(:banned)
      end
    end
  end
end
