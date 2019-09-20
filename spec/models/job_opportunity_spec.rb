require "rails_helper"

RSpec.describe JobOpportunity, type: :model do
  it "returns remoteness in words for remoteness" do
    jo = described_class.new
    jo.remoteness = "on_premise"
    expect(jo.remoteness_in_words).to eq("In Office")
  end
end
