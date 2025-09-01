require "rails_helper"

RSpec.describe DigestMailer do
  let(:user) { create(:user) }
  let(:article) { create(:article, title: "Test Article Title") }
  let(:from_email_address) { "custom_noreply@forem.com" }

  describe "#digest_email" do
    before do
      allow(Settings::SMTP).to receive_messages(
        provided_minimum_settings?: true,
        from_email_address: from_email_address,
      )
      allow(ForemInstance).to receive(:sendgrid_enabled?).and_return(true)
    end

    it "works correctly", :aggregate_failures do
      email = described_class.with(user: user, articles: [article]).digest_email

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([from_email_address])
      expected_from = "#{Settings::Community.community_name} Digest <#{from_email_address}>"
      expect(email["from"].value).to eq(expected_from)
    end

    it "includes the correct X-SMTPAPI header for SendGrid", :aggregate_failures do
      email = described_class.with(user: user, articles: [article]).digest_email.deliver_now

      expect(email.header["X-SMTPAPI"]).not_to be_nil
      smtpapi_header = JSON.parse(email.header["X-SMTPAPI"].value)
      expect(smtpapi_header).to have_key("category")
      expect(smtpapi_header["category"]).to include("Digest Email")
    end

    it "includes billboard html in body" do
      bb_1 = create(:billboard, placement_area: "digest_first", published: true, approved: true)
      bb_2 = create(:billboard, placement_area: "digest_second", published: true, approved: true)

      email = described_class.with(user: user, articles: [article], billboards: [bb_1, bb_2]).digest_email

      expect(email.body.encoded).to include(bb_1.processed_html)
      expect(email.body.encoded).to include(bb_2.processed_html)
    end
  end

  describe "#generate_title" do
    before do
      allow(ForemInstance).to receive(:dev_to?).and_return(true)
    end

    context "when user follows no subforems" do
      it "uses DEV Digest in subject" do
        allow_any_instance_of(DigestMailer).to receive(:user_follows_any_subforems?).and_return(false)

        email = described_class.with(user: user, articles: [article]).digest_email
        expect(email.subject).to include("| DEV Digest")
      end
    end

    context "when user follows one subforem" do
      it "uses Forem Digest in subject" do
        allow_any_instance_of(DigestMailer).to receive(:user_follows_any_subforems?).and_return(true)

        email = described_class.with(user: user, articles: [article]).digest_email
        expect(email.subject).to include("| Forem Digest")
      end
    end

    context "when user follows multiple subforems" do
      it "uses Forem Digest in subject" do
        allow_any_instance_of(DigestMailer).to receive(:user_follows_any_subforems?).and_return(true)

        email = described_class.with(user: user, articles: [article]).digest_email
        expect(email.subject).to include("| Forem Digest")
      end
    end

    context "when not on DEV.to" do
      it "does not include digest suffix" do
        allow(ForemInstance).to receive(:dev_to?).and_return(false)

        email = described_class.with(user: user, articles: [article]).digest_email
        expect(email.subject).to eq("Test Article Title")
        expect(email.subject).not_to include("| DEV Digest")
        expect(email.subject).not_to include("| Forem Digest")
      end
    end

    context "when user has custom onboarding subforem" do
      let(:custom_onboarding_subforem) { create(:subforem, domain: "custom.test") }
      let(:default_subforem) { create(:subforem, domain: "default.test") }

      before do
        user.update!(onboarding_subforem_id: custom_onboarding_subforem.id)
        allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
      end

      it "uses Forem Digest in subject when onboarding subforem is not default" do
        # User has no followed subforems but has custom onboarding subforem
        # The method should return true due to custom onboarding subforem
        email = described_class.with(user: user, articles: [article]).digest_email
        expect(email.subject).to include("| Forem Digest")
      end

      it "uses DEV Digest in subject when onboarding subforem is default" do
        user.update!(onboarding_subforem_id: default_subforem.id)
        # User has no followed subforems and onboarding subforem is default
        # The method should return false
        email = described_class.with(user: user, articles: [article]).digest_email
        expect(email.subject).to include("| DEV Digest")
      end
    end
  end
end
