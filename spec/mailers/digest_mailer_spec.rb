require "rails_helper"

RSpec.describe DigestMailer do
  let(:user) { create(:user) }
  let(:article) { build_stubbed(:article) }
  let(:from_email_address) { "custom_noreply@forem.com" }

  describe "#digest_email" do
    before do
      allow(article).to receive(:title).and_return("test title")
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

    it "works with all field_test variants", :aggregate_failures do
      allow(FeatureFlag).to receive(:enabled?).with(:digest_subject_testing).and_return(true)
      variants = %w[base base_with_no_emoji base_with_start_with_dev_digest
                    base_with_start_with_dev_digest_and_no_emoji just_first_title just_first_title_and_dev_digest]
      variants.each do |variant|
        allow(described_class).to receive(:title_test_variant)
          .with(user).and_return(variant)
        email = described_class.with(user: user, articles: [article]).digest_email

        expect(email.subject).not_to be_nil
      end
    end

    it "includes the correct X-SMTPAPI header for SendGrid", :aggregate_failures do
      email = described_class.with(user: user, articles: [article]).digest_email.deliver_now

      expect(email.header["X-SMTPAPI"]).not_to be_nil
      smtpapi_header = JSON.parse(email.header["X-SMTPAPI"].value)
      expect(smtpapi_header).to have_key("category")
      expect(smtpapi_header["category"]).to include("Digest Email")
    end
  end
end
