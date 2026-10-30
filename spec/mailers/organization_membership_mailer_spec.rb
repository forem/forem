require "rails_helper"

RSpec.describe OrganizationMembershipMailer do
  let(:user) { create(:user) }
  let(:domain) { create(:organization_email_domain, :available) }
  let(:challenge) do
    OrganizationMembershipChallenge.create!(user: user, organization_email_domain: domain,
                                            email: "employee@foobar.com", otp_digest: "digest",
                                            expires_at: 10.minutes.from_now)
  end
  let(:mail) { described_class.with(challenge_id: challenge.id, otp: "12345678").verification_email }

  it "addresses the work mailbox, never the primary account mailbox" do
    expect(mail.to).to eq(["employee@foobar.com"])
    expect(mail.subject).to include(domain.organization.name)
    expect(mail.body.encoded).to include("12345678")
    expect(mail.body.encoded).not_to include(user.email)
    html = Nokogiri::HTML(mail.html_part.body.decoded)
    expect(html.at_css("h1").text).to eq("Join #{domain.organization.name}")
    expect(html.css("table[role=presentation]").text).to include("12345678")
    expect(mail.text_part.body.decoded).to include("12345678")
  end

  it "redacts the code and work address from delivery instrumentation" do
    allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    payload = nil
    subscriber = ->(event) { payload = event.payload }
    ActiveSupport::Notifications.subscribed(subscriber, "deliver.action_mailer") { mail.deliver_now }
    expect(payload[:mail]).to eq("[FILTERED]")
    expect(payload[:to]).to eq(["[FILTERED]"])
    expect(ActionMailer::Base.deliveries.last.body.encoded).to include("12345678")
  end

  it "does not send expired challenges" do
    challenge.update!(expires_at: 1.minute.ago)
    expect(mail.message).to be_a(ActionMailer::Base::NullMail)
  end

  it "does not send revoked challenges" do
    domain.update!(status: "revoked")
    expect(mail.message).to be_a(ActionMailer::Base::NullMail)
  end

  it "uses the work email as the Customer.io identifier with tracking disabled" do
    allow(ForemInstance).to receive(:customerio_enabled?).and_return(true)
    FeatureFlag.enable(:customerio_email_delivery)
    expect(mail.delivery_method).to be_a(DeliveryMethods::CustomerIo)
    expect(mail.delivery_method.settings[:identifiers]).to eq(email: "employee@foobar.com")
    expect(mail.delivery_method.settings[:tracked]).to be(false)
  end
end
