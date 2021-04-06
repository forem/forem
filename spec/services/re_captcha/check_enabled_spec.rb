require "rails_helper"

RSpec.describe ReCaptcha::CheckEnabled, type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:recent_user) { create(:user) }
  let(:older_user) { create(:user, created_at: 3.months.ago) }
  let(:trusted_user) { create(:user, :trusted) }
  let(:vomitted_user) do
    user = create(:user, created_at: 3.months.ago)
    create(:vomit_reaction, category: "vomit", reactable: user, user: trusted_user, status: "confirmed")
    user
  end

  describe "ReCaptcha for user actions like Abuse Reports (FeedbackMessages)" do
    context "when recaptcha SiteConfig keys are not configured" do
      it "marks ReCaptcha as not enabled regardless of the param passed in" do
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return(nil)
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return(nil)

        expect(described_class.call).to be(false)
        expect(described_class.call(older_user)).to be(false)
      end
    end

    context "when recaptcha SiteConfig keys are configured" do
      before do
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("someSecretKey")
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return("someSiteKey")
      end

      it "marks ReCaptcha as enabled when logged out (parameter is nil)" do
        expect(described_class.call).to be(true)
      end

      it "marks ReCaptcha as not enabled when older user is logged in" do
        sign_in older_user
        expect(described_class.call(older_user)).to be(false)
      end

      it "marks ReCaptcha as not enabled when admin is logged in" do
        sign_in admin
        expect(described_class.call(admin)).to be(false)
      end

      it "marks ReCaptcha as not enabled when trusted user is logged in" do
        sign_in trusted_user
        expect(described_class.call(trusted_user)).to be(false)
      end

      it "marks ReCaptcha as enabled when user with vomits is logged in" do
        sign_in vomitted_user
        expect(described_class.call(vomitted_user)).to be(true)
      end

      it "marks ReCaptcha as enabled when a suspended user is logged in" do
        older_user.add_role(:suspended)
        sign_in older_user
        expect(described_class.call(older_user)).to be(true)
        older_user.remove_role(:suspended)
      end
    end
  end
end
