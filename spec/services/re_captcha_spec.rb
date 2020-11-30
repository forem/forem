require "rails_helper"

RSpec.describe ReCaptcha, type: :request do
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

  describe "ReCaptcha for user actions (like Feedback/Reports)" do
    context "when recaptcha keys are not configured" do
      before do
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return(nil)
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return(nil)
      end

      it "returns correct enabled? and disabled?" do
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

      context "when logged out" do
        it "is enabled" do
          expect(ReCaptcha.call.enabled?).to be(true)
          expect(ReCaptcha.call.disabled?).to be(false)
        end
      end

      context "when older user is logged in without vomits" do
        before { sign_in older_user }

        it "returns correct enabled? and disabled? for vomitted user" do
          expect(ReCaptcha.call(older_user).enabled?).to be(false)
          expect(ReCaptcha.call(older_user).disabled?).to be(true)
        end
      end

      context "when admin is logged in" do
        before { sign_in admin }

        it "returns correct enabled? and disabled? for vomitted user" do
          expect(ReCaptcha.call(admin).enabled?).to be(false)
          expect(ReCaptcha.call(admin).disabled?).to be(true)
        end
      end

      context "when trusted user is logged in" do
        before { sign_in trusted_user }

        it "returns correct enabled? and disabled? for vomitted user" do
          expect(ReCaptcha.call(trusted_user).enabled?).to be(false)
          expect(ReCaptcha.call(trusted_user).disabled?).to be(true)
        end
      end

      context "when user with vomits is logged in" do
        before { sign_in vomitted_user }

        it "returns correct enabled? and disabled? for vomitted user" do
          expect(ReCaptcha.call(vomitted_user).enabled?).to be(true)
          expect(ReCaptcha.call(vomitted_user).disabled?).to be(false)
        end
      end
    end
  end
end
