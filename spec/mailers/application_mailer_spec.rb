require "rails_helper"

RSpec.describe ApplicationMailer do
  let(:user) { create(:user) }
  let(:email) { VerificationMailer.with(user_id: user.id).account_ownership_verification_email }

  describe "#set_perform_deliveries" do
    it "changes perform_deliveries from true to false if smtp is not enabled" do
      expect { email.deliver_now }.to change(described_class, :perform_deliveries).from(true).to(false)
    end

    it "changes perform_deliveries from false to true if smtp is enabled" do
      described_class.perform_deliveries = false
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)

      expect { email.deliver_now }.to change(described_class, :perform_deliveries).from(false).to(true)
    end
  end

  describe "#set_delivery_options" do
    after do
      Settings::SMTP.clear_cache
    end

    it "sets proper SMTP credential during callback" do
      Settings::SMTP.address = "smtp.google.com"
      Settings::SMTP.user_name = Faker::Internet.username
      Settings::SMTP.password = Faker::Internet.password
      email.deliver_now

      expect(described_class.deliveries.last.delivery_method.settings).to eq(Settings::SMTP.settings)
    end
  end

  context "magic link heads up logic" do
    it "includes the magic link heads up if user has no page views past 4 weeks" do
      create(:page_view, user: user, created_at: 5.weeks.ago)
      user.page_views.destroy_all

      email.deliver_now

      expect(email.body.encoded).to include("Not signed-in on this device?")
    end

    it "does not include the magic link heads up if user has page views past 4 weeks" do
      # Ensure recent page view exists
      create(:page_view, user: user, created_at: 3.weeks.ago)

      email.deliver_now

      expect(email.body.encoded).not_to include("Not signed-in on this device?")
    end
  end

  describe "#setup_subforem_context" do
    let!(:subforem) { create(:subforem, domain: "test.example.com") }
    let!(:default_subforem) { create(:subforem, domain: "default.example.com") }
    let(:subforem_community_name) { "Test Community" }
    let(:default_community_name) { "Default Community" }

    before do
      allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
      allow(Subforem).to receive(:cached_default_domain).and_return(default_subforem.domain)
      allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({
        subforem.id => subforem.domain,
        default_subforem.id => default_subforem.domain
      })
      allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem.id).and_return(subforem_community_name)
      allow(Settings::Community).to receive(:community_name).with(subforem_id: default_subforem.id).and_return(default_community_name)
      allow(Settings::General).to receive(:app_domain).and_return("fallback.example.com")
    end

    context "when user has onboarding_subforem_id" do
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }
      let(:email) { NotifyMailer.with(user: user_with_subforem).unread_notifications_email }

      it "sets subforem_id from user's onboarding_subforem_id" do
        email.deliver_now
        expect(email.subject).to include(subforem_community_name)
      end

      it "sets subforem_domain from the subforem's domain" do
        email.deliver_now
        # Check the URL in the email contains the subforem domain
        expect(email.body.encoded).to include(subforem.domain)
      end

      it "uses the subforem's community name in the from address" do
        email.deliver_now
        expect(email.from.first).to include(ForemInstance.from_email_address)
      end
    end

    context "when user has nil onboarding_subforem_id" do
      let(:user_without_subforem) { create(:user, onboarding_subforem_id: nil) }
      let(:email) { NotifyMailer.with(user: user_without_subforem).unread_notifications_email }

      it "falls back to default subforem_id" do
        email.deliver_now
        expect(email.subject).to include(default_community_name)
      end

      it "uses default subforem domain" do
        email.deliver_now
        expect(email.body.encoded).to include(default_subforem.domain)
      end
    end

    context "when subforem_id doesn't exist in hash" do
      let(:user_with_invalid_subforem) { create(:user, onboarding_subforem_id: 99999) }
      let(:email) { NotifyMailer.with(user: user_with_invalid_subforem).unread_notifications_email }

      before do
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({})
        allow(Settings::Community).to receive(:community_name).and_call_original
        allow(Settings::Community).to receive(:community_name).with(subforem_id: 99999).and_return(default_community_name)
      end

      it "falls back to default domain" do
        email.deliver_now
        expect(email.body.encoded).to include(default_subforem.domain)
      end
    end

    context "when no subforems exist" do
      let(:email) { NotifyMailer.with(user: user).unread_notifications_email }

      before do
        allow(Subforem).to receive(:cached_default_id).and_return(nil)
        allow(Subforem).to receive(:cached_default_domain).and_return(nil)
        allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({})
        allow(Settings::Community).to receive(:community_name).and_call_original
        allow(Settings::Community).to receive(:community_name).with(subforem_id: nil).and_return(default_community_name)
      end

      it "falls back to Settings::General.app_domain" do
        email.deliver_now
        expect(email.body.encoded).to include("fallback.example.com")
      end
    end

    context "in development environment" do
      let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }
      let(:email) { NotifyMailer.with(user: user_with_subforem).unread_notifications_email }

      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "adds :3000 port to domain" do
        email.deliver_now
        expect(email.body.encoded).to include("#{subforem.domain}:3000")
      end
    end
  end

  describe "#email_from" do
    let!(:subforem) { create(:subforem, domain: "custom.example.com") }
    let(:subforem_community_name) { "Custom Community" }
    let(:user_with_subforem) { create(:user, onboarding_subforem_id: subforem.id) }

    before do
      allow(Subforem).to receive(:cached_default_id).and_return(subforem.id)
      allow(Subforem).to receive(:cached_id_to_domain_hash).and_return({ subforem.id => subforem.domain })
      allow(Subforem).to receive(:cached_default_domain).and_return(subforem.domain)
      allow(Settings::Community).to receive(:community_name).with(subforem_id: subforem.id).and_return(subforem_community_name)
      allow(ForemInstance).to receive(:from_email_address).and_return("noreply@forem.com")
    end

    it "includes subforem's community name in from address" do
      email = NotifyMailer.with(user: user_with_subforem).unread_notifications_email
      email.deliver_now
      
      expect(email["from"].value).to include(subforem_community_name)
      expect(email["from"].value).to include("noreply@forem.com")
    end

    it "includes topic in from address when provided" do
      allow(Settings::Community).to receive(:community_name).and_call_original
      allow(Settings::Community).to receive(:community_name).with(no_args).and_return(subforem_community_name)
      
      email = DigestMailer.with(user: user_with_subforem, articles: [create(:article)], billboards: []).digest_email
      email.deliver_now
      
      # DigestMailer uses email_from with a topic
      expect(email["from"].value).to include("noreply@forem.com")
    end
  end
end
