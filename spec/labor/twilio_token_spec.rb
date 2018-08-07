require "rails_helper"

RSpec.describe TwilioToken do
  let(:user) { create(:user) }

  it "returns a token" do
    expect(described_class.new(user, "hello").get.size).to be > 0
  end
end
