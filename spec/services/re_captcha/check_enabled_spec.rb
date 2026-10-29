require "rails_helper"

RSpec.describe ReCaptcha::CheckEnabled do
  let(:admin) { create(:user, :super_admin) }
  let(:older_user) { create(:user, created_at: 3.months.ago) }
  let(:trusted_user) { create(:user, :trusted) }
  let(:vomited_user) do
    user = create(:user, created_at: 3.months.ago)
    create(:vomit_reaction, category: "vomit", reactable: user, user: trusted_user, status: "confirmed")
    user
  end

  describe "ReCaptcha for user actions like Abuse Reports (FeedbackMessages)" do
    context "when recaptcha Settings::General keys are not configured" do
      it "marks ReCaptcha as not enabled regardless of the param passed in", :aggregate_failures do
        allow(Settings::Authentication).to receive_messages(recaptcha_site_key: nil, recaptcha_secret_key: nil)

        expect(described_class.call).to be(false)
        expect(described_class.call(older_user)).to be(false)
      end
    end

    context "when recaptcha Settings::General keys are configured" do
      before do
        allow(Settings::Authentication).to receive_messages(recaptcha_site_key: "someSecretKey",
                                                            recaptcha_secret_key: "someSiteKey")
      end

      it "marks ReCaptcha as enabled when logged out (parameter is nil)" do
        expect(described_class.call).to be(true)
      end

      it "marks ReCaptcha as not enabled for an older user and loads roles once", :aggregate_failures do
        older_user
        role_queries = []
        subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
          role_queries << payload[:sql] if payload[:sql].include?('FROM "roles"')
        end

        ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
          expect(described_class.call(older_user)).to be(false)
        end

        expect(role_queries.size).to eq(1)
      end

      it "marks ReCaptcha as not enabled when admin is logged in" do
        expect(described_class.call(admin)).to be(false)
      end

      it "marks ReCaptcha as not enabled when trusted user is logged in" do
        expect(described_class.call(trusted_user)).to be(false)
      end

      it "marks ReCaptcha as enabled when user with vomits is logged in" do
        expect(described_class.call(vomited_user)).to be(true)
      end

      it "marks ReCaptcha as enabled when a suspended or spam user is logged in", :aggregate_failures do
        older_user.add_role(:suspended)
        expect(described_class.call(older_user)).to be(true)
        older_user.remove_role(:suspended)

        older_user.add_role(:spam)
        expect(described_class.call(older_user)).to be(true)
        older_user.remove_role(:spam)
      end
    end
  end
end
