require "rails_helper"

RSpec.describe UserFollowSuggester, vcr: {} do
  let(:user) { create(:user) }

  it "does not include calling user" do
    create(:user)
    create(:user)
    create(:user)
    expect(described_class.new(user).suggestions).not_to include(user)
  end
  it "does not include calling user" do
    create(:user)
    create(:user)
    create(:user)
    expect(described_class.new(user).suggestions.size).to eq(3)
  end
end
