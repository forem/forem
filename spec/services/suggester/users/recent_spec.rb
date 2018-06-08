require "rails_helper"

RSpec.describe Suggester::Users::Recent, vcr: {} do
  let(:user) { create(:user) }

  it "does not include calling user" do
    3.times { create(:user) }
    expect(described_class.new(user).suggest).not_to include(user)
  end

  it "returns the same number created" do
    3.times { create(:user) }
    expect(described_class.new(user).suggest.size).to eq(3)
  end
end
