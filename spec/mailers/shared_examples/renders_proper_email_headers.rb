RSpec.shared_examples "#renders_proper_email_headers" do
  it "renders proper sender" do
    expect(email.from).to eq([Settings::General.email_addresses[:default]])
    expected_from = "#{Settings::Community.community_name} <#{Settings::General.email_addresses[:default]}>"
    expect(email["from"].value).to eq(expected_from)
  end

  it "renders proper reply_to" do
    expect(email["reply_to"].value).to eq(Settings::General.email_addresses[:default])
  end
end
