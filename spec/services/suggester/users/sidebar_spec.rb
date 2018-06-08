require "rails_helper"
# TODO: improve this test
RSpec.describe Suggester::Users::Sidebar do
  let(:user) { create(:user) }

  it "does not include calling user" do
    3.times { create(:user) }
    tags = []
    3.times { tags << create(:tag) }
    expect(described_class.new(user, tags).suggest).not_to include(user)
  end

  it "returns the same number created" do
    3.times { create(:user) }
    tags = []
    3.times { tags << create(:tag) }
    expect(described_class.new(user, tags).suggest.size).to eq(0)
  end
end
