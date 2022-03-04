RSpec.shared_examples "#renders_proper_email_headers" do
  let(:from_email_address) { "custom_noreply@forem.com" }
  let(:reply_to_email_address) { "custom_reply@forem.com" }

  before do
    allow(Settings::SMTP).to receive(:provided_minimum_settings?).and_return(true)
    allow(Settings::SMTP).to receive(:from_email_address).and_return(from_email_address)
    allow(Settings::SMTP).to receive(:reply_to_email_address).and_return(reply_to_email_address)
  end

  it "renders proper sender", :aggregate_failures do
    expect(email.from).to eq([from_email_address])
    expected_from = "#{Settings::Community.community_name} <#{from_email_address}>"
    expect(email["from"].value).to eq(expected_from)
  end

  it "renders proper reply_to" do
    expect(email["reply_to"].value).to eq(reply_to_email_address)
  end
end
