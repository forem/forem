require "rails_helper"

RSpec.describe Twilio::GetJwtToken, type: :service do
  let(:user) { create(:user) }

  it "returns a token" do
    expect(described_class.call(user, "hello")).to be_present
  end
end
