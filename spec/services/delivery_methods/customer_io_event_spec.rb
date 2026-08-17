require "rails_helper"

RSpec.describe DeliveryMethods::CustomerIoEvent do
  let(:track_client) { instance_double(Customerio::Client, batch: nil) }
  let(:mail) do
    Mail.new(
      from: "DEV Community <hello@dev.to>",
      to: "member@example.com",
      subject: "Your digest",
      body: "<p>Hello there</p>",
    )
  end

  before do
    stub_const("CUSTOMERIO_TRACK_API", track_client)
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("APP_NAME").and_return("dev_prod")
  end

  def delivered_entity(options = {}, delivered_mail = mail)
    described_class.new(options).deliver!(delivered_mail)
    operations = nil
    expect(track_client).to have_received(:batch) { |ops| operations = ops }
    expect(operations.size).to eq(1)
    operations.first
  end

  it "emits a person event carrying the payload" do
    entity = delivered_entity(
      customerio_event_name: "digest_ready",
      identifiers: { id: "mlh-42" },
      message_data: { "articles" => [{ "title" => "A post" }] },
    )

    expect(entity[:type]).to eq("person")
    expect(entity[:action]).to eq("event")
    expect(entity[:name]).to eq("dev_prod_digest_ready")
    expect(entity[:identifiers]).to eq(id: "mlh-42")
    expect(entity[:attributes]["articles"]).to eq([{ "title" => "A post" }])
  end

  # The Customer.io profile is keyed on the MLH person, whose primary address is
  # not necessarily the DEV one, so the campaign cannot address the mail without
  # being told where it goes.
  it "sets recipient to the mail's own address, not the identifier" do
    entity = delivered_entity(customerio_event_name: "digest_ready", identifiers: { id: "mlh-42" })

    expect(entity[:attributes]["recipient"]).to eq("member@example.com")
    expect(entity[:attributes]["subject"]).to eq("Your digest")
  end

  it "lets message_data override the defaults" do
    entity = delivered_entity(
      customerio_event_name: "digest_ready",
      message_data: { "subject" => "Overridden" },
    )

    expect(entity[:attributes]["subject"]).to eq("Overridden")
  end

  # A Track event name is the campaign's trigger, so it carries the same
  # APP_NAME namespace the CDP adapter applies -- one instance's digest must not
  # trigger another's campaign in a shared workspace.
  describe "APP_NAME event prefixing" do
    it "namespaces the mailer's bare event name with APP_NAME" do
      entity = delivered_entity(customerio_event_name: "digest_ready")

      expect(entity[:name]).to eq("dev_prod_digest_ready")
    end

    it "falls back to the 'forem' prefix when APP_NAME is unset" do
      allow(ApplicationConfig).to receive(:[]).with("APP_NAME").and_return(nil)

      entity = delivered_entity(customerio_event_name: "digest_ready")

      expect(entity[:name]).to eq("forem_digest_ready")
    end

    it "falls back to the 'forem' prefix when APP_NAME is blank" do
      allow(ApplicationConfig).to receive(:[]).with("APP_NAME").and_return("")

      entity = delivered_entity(customerio_event_name: "digest_ready")

      expect(entity[:name]).to eq("forem_digest_ready")
    end
  end

  it "raises when Customer.io rejects the event, so Ahoy records no send" do
    allow(track_client).to receive(:batch).and_raise(Customerio::InvalidResponse.new(400, "bad request"))

    expect { described_class.new(customerio_event_name: "x").deliver!(mail) }
      .to raise_error(Customerio::InvalidResponse)
  end

  # Customer.io renders from the event payload, so Ahoy's rewriting of the
  # ActionMailer body never reaches the recipient.
  describe "click tracking in the payload" do
    let(:article_url) { "https://#{Settings::General.app_domain}/ben/some-post" }

    it "decorates message_data links using the token Ahoy set on the mail" do
      mail.ahoy_data = { token: "tok123", campaign: nil }

      entity = delivered_entity(
        customerio_event_name: "digest_ready",
        message_data: { "url" => article_url },
      )

      params = Rack::Utils.parse_query(Addressable::URI.parse(entity[:attributes]["url"]).query)
      expect(params["ahoy_click"]).to eq("true")
      expect(params["t"]).to eq("tok123")
    end

    it "leaves message_data alone when Ahoy did not set a token" do
      entity = delivered_entity(
        customerio_event_name: "digest_ready",
        message_data: { "url" => article_url },
      )

      expect(entity[:attributes]["url"]).to eq(article_url)
    end
  end
end
