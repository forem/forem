RSpec.shared_examples "#renders_proper_email_headers" do
  it "renders proper sender" do
    expect(email.from).to eq([ForemInstance.email])
    expected_from = "#{Settings::Community.community_name} <#{ForemInstance.email}>"
    expect(email["from"].value).to eq(expected_from)
  end

  it "renders proper reply_to" do
    expect(email["reply_to"].value).to eq(ForemInstance.email)
  end
end
# require "rails_helper"
#
# RSpec.shared_examples "#renders_proper_email_headers" do
#   let(:from_email_address) { "noreply@dev.to" }
#   let(:reply_to_email_address) { "yo@dev.to" }
#
#   before do
#     allow(Settings::SMTP).to receive(:from_email_address).and_return(from_email_address)
#     allow(Settings::SMTP).to receive(:reply_to_email_address).and_return(reply_to_email_address)
#   end
#
#   it "renders proper sender" do
#     expect(email.from).to eq([from_email_address])
#     expected_from = "#{Settings::Community.community_name} <#{from_email_address}>"
#     expect(email["from"].value).to eq(expected_from)
#   end
#
#   it "renders proper reply_to" do
#     expect(email["reply_to"].value).to eq(reply_to_email_address)
#   end
# end
