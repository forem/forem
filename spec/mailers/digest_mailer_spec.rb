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

    it "renders the article ai_summary when present" do
      article.update_columns(ai_summary: "An AI generated summary of the article.",
                             description: "Original description text.")

      email = described_class.with(user: user, articles: [article]).digest_email

      expect(email.body.encoded).to include("An AI generated summary of the article.")
      expect(email.body.encoded).not_to include("Original description text.")
    end

    it "falls back to the truncated description when ai_summary is blank" do
      article.update_columns(ai_summary: nil, description: "Fallback description text.")

      email = described_class.with(user: user, articles: [article]).digest_email

      expect(email.body.encoded).to include("Fallback description text.")
    end

    it "includes billboard html in body" do
      bb_1 = create(:billboard, placement_area: "digest_first", published: true, approved: true)
      bb_2 = create(:billboard, placement_area: "digest_second", published: true, approved: true)

      email = described_class.with(user: user, articles: [article], billboards: [bb_1, bb_2]).digest_email

      expect(email.body.encoded).to include(bb_1.processed_html)
      expect(email.body.encoded).to include(bb_2.processed_html)
    end

    it "includes the feed_config_id in email links when present" do
      email = described_class.with(user: user, articles: [article], feed_config_id: 12345).digest_email
      
      expect(email.body.encoded).to include("fc=12345")
    end

    it "does not include fc parameter in email links when feed_config_id is nil" do
      email = described_class.with(user: user, articles: [article], feed_config_id: nil).digest_email

      expect(email.body.encoded).not_to include("fc=")
    end

    it "does not use Customer.io delivery when Customer.io is not configured" do
      email = described_class.with(user: user, articles: [article]).digest_email

      expect(email.message.delivery_method).not_to be_a(DeliveryMethods::CustomerIo)
    end

    context "when routed through Customer.io" do
      let(:article2) { create(:article, title: "Second Article Title") }

      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "still sets the X-SMTPAPI header for SendGrid alongside the Customer.io payload", :aggregate_failures do
        email = described_class.with(user: user, articles: [article]).digest_email

        expect(email.header["X-SMTPAPI"]).not_to be_nil
        expect(email.message.delivery_method).to be_a(DeliveryMethods::CustomerIo)
      end

      it "routes through the Customer.io digest template with the full payload", :aggregate_failures do
        article.update_columns(ai_summary: "An AI generated summary.", description: "Original description.")

        email = described_class.with(user: user, articles: [article, article2], feed_config_id: 12_345).digest_email

        settings = email.message.delivery_method.settings
        expect(settings[:transactional_message_id]).to eq("dev_digest_email")

        data = settings[:message_data]
        expect(data["subject"]).to eq(email.subject)
        expect(data["articles"].size).to eq(2)

        expected_url = ApplicationController.helpers.article_url(article, context: "digest", fc: 12_345)
        expect(data["articles"].first["title"]).to eq(article.title.strip)
        expect(data["articles"].first["url"]).to eq(expected_url)
        expect(data["articles"].first["summary"]).to eq("An AI generated summary.")
        expect(data["articles"].second["title"]).to eq(article2.title.strip)

        expect(data["unsubscribe_url"]).to include("ut=")
        expect(data["user_follows_any_subforems"]).to be(false)
        expect(data).to have_key("smart_summary")
        expect(data["email_end_phrase"]).to be_present
      end

      it "falls back to the truncated description in the payload when ai_summary is blank" do
        article.update_columns(ai_summary: nil, description: "Fallback description text.")

        email = described_class.with(user: user, articles: [article]).digest_email

        data = email.message.delivery_method.settings[:message_data]
        expect(data["articles"].first["summary"]).to eq("Fallback description text.")
      end

      it "passes the smart_summary through untouched" do
        email = described_class.with(user: user, articles: [article],
                                     smart_summary: "Digest overview text").digest_email

        data = email.message.delivery_method.settings[:message_data]
        expect(data["smart_summary"]).to eq("Digest overview text")
      end

      it "includes billboards_html for each rendered billboard, in order" do
        bb_1 = create(:billboard, placement_area: "digest_first", published: true, approved: true)
        bb_2 = create(:billboard, placement_area: "digest_second", published: true, approved: true)

        email = described_class.with(user: user, articles: [article], billboards: [bb_1, bb_2]).digest_email

        data = email.message.delivery_method.settings[:message_data]
        expect(data["billboards_html"]).to eq([bb_1.processed_html, bb_2.processed_html])
      end

      it "omits billboards_html entries when no billboards are given" do
        email = described_class.with(user: user, articles: [article]).digest_email

        data = email.message.delivery_method.settings[:message_data]
        expect(data["billboards_html"]).to eq([])
      end
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
