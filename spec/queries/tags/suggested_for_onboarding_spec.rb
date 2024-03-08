require "rails_helper"

RSpec.describe Tags::SuggestedForOnboarding, type: :query do
  subject(:result) { described_class.call }

  let!(:suggested_tags) do
    create(:tag, suggested: true)
    create(:tag, suggested: true)
    create(:tag, suggested: true)
    Tag.where(suggested: true)
  end

  it "starts with Settings::General::SuggestedTags" do
    expect(result).to match_array(suggested_tags)
  end

  context "when suggested tags aren't enough" do
    let!(:supported) { create(:tag, supported: true) }

    it "adds supported tags" do
      expect(Tag.count < Tags::SuggestedForOnboarding::MAX).to be_truthy
      expect(result).to include(*suggested_tags)
      expect(result).to include(supported)
    end
  end
end
