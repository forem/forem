require "rails_helper"

RSpec.describe DeliveryMethods::CustomerIo do
  let(:api_client) { instance_double(Customerio::APIClient, send_email: { "delivery_id" => "dev-123" }) }
  let(:mail) do
    Mail.new(
      from: "DEV Community <hello@dev.to>",
      to: "member@example.com",
      reply_to: "reply@dev.to",
      subject: "Welcome!",
      body: "<p>Hello there</p>",
    )
  end

  before { stub_const("CUSTOMERIO_API", api_client) }

  def delivered_message(options = {}, delivered_mail = mail)
    described_class.new(options).deliver!(delivered_mail)
    request = nil
    expect(api_client).to have_received(:send_email) { |req| request = req }
    request.message
  end

  it "sends the rendered body when no transactional_message_id is configured" do
    message = delivered_message
    expect(message[:body]).to eq("<p>Hello there</p>")
    expect(message[:subject]).to eq("Welcome!")
    expect(message[:from]).to eq("hello@dev.to")
    expect(message[:reply_to]).to eq("reply@dev.to")
    expect(message[:to]).to eq("member@example.com")
    expect(message[:identifiers]).to eq(email: "member@example.com")
    expect(message[:tracked]).to be(true)
  end

  it "omits the body when a transactional_message_id is present so Customer.io renders the template" do
    message = delivered_message(transactional_message_id: "dev_test_template", message_data: { "name" => "Sloan" })
    expect(message).not_to have_key(:body)
    expect(message[:transactional_message_id]).to eq("dev_test_template")
    expect(message[:message_data]).to eq("name" => "Sloan")
  end

  it "forwards the one-click unsubscribe headers so RFC 8058 survives the Customer.io render" do
    mail["List-Unsubscribe"] = "<https://dev.to/email_subscriptions/unsubscribe?ut=token>"
    mail["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    message = delivered_message(transactional_message_id: "dev_test_template")

    expect(message[:headers]).to eq(
      "List-Unsubscribe" => "<https://dev.to/email_subscriptions/unsubscribe?ut=token>",
      "List-Unsubscribe-Post" => "List-Unsubscribe=One-Click",
    )
  end

  it "sends no custom headers when the mail carries no unsubscribe headers" do
    expect(delivered_message[:headers]).to eq({})
  end

  it "prefers identifiers passed in options over the recipient email" do
    message = delivered_message(identifiers: { id: "42" })
    expect(message[:identifiers]).to eq(id: "42")
  end

  it "prefers the html part of a multipart body" do
    multipart = Mail.new(from: "hello@dev.to", to: "member@example.com", subject: "Hi") do
      text_part { body "plain text" }
      html_part { body "<p>html</p>" }
    end
    message = delivered_message({}, multipart)
    expect(message[:body]).to eq("<p>html</p>")
  end

  it "prefers the html part when the mail is multipart/mixed with an attachment" do
    # e.g. the export-email flow: an alternative (text+html) part plus a file
    # attachment. Mail nests the alternative part inside the mixed part, so
    # html_part must be found recursively rather than assuming it's top-level.
    mixed = Mail.new(from: "hello@dev.to", to: "member@example.com", subject: "Export") do
      text_part { body "plain export" }
      html_part { body "<p>html export</p>" }
      add_file(filename: "export.csv", content: "a,b,c")
    end
    message = delivered_message({}, mixed)
    expect(message[:body]).to eq("<p>html export</p>")
  end

  # Customer.io renders its own template, so Ahoy's rewriting of the
  # ActionMailer body never reaches the recipient. The payload has to carry the
  # tracking params instead or Ahoy::EmailClicksController is never called.
  describe "click tracking in the payload" do
    let(:article_url) { "https://#{Settings::General.app_domain}/ben/some-post" }

    it "decorates message_data links using the token Ahoy set on the mail" do
      mail.ahoy_data = { token: "tok123", campaign: nil }

      message = delivered_message(
        transactional_message_id: "dev_test_template",
        message_data: { "url" => article_url },
      )

      params = Rack::Utils.parse_query(Addressable::URI.parse(message[:message_data]["url"]).query)
      expect(params["ahoy_click"]).to eq("true")
      expect(params["t"]).to eq("tok123")
    end

    it "leaves message_data alone when Ahoy did not set a token" do
      message = delivered_message(
        transactional_message_id: "dev_test_template",
        message_data: { "url" => article_url },
      )

      expect(message[:message_data]["url"]).to eq(article_url)
    end
  end

  it "attaches mail attachments to the request" do
    mail.attachments["export.zip"] = "zipbytes"
    request_double = instance_double(Customerio::SendEmailRequest, attach: nil, message: {})
    allow(Customerio::SendEmailRequest).to receive(:new).and_return(request_double)

    described_class.new({}).deliver!(mail)

    expect(request_double).to have_received(:attach).with("export.zip", "zipbytes")
    expect(api_client).to have_received(:send_email).with(request_double)
  end
end
