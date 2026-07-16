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

  it "prefers identifiers passed in options over the recipient email" do
    message = delivered_message(identifiers: { id: "42" })
    expect(message[:identifiers]).to eq(id: "42")
  end

  it "uses the first part of a multipart body" do
    multipart = Mail.new(from: "hello@dev.to", to: "member@example.com", subject: "Hi") do
      text_part { body "plain text" }
      html_part { body "<p>html</p>" }
    end
    message = delivered_message({}, multipart)
    expect(message[:body]).to eq("plain text")
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
