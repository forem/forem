require "rails_helper"

RSpec.describe ProfileImage, type: :labor do
  let(:user) { create(:user) }

  it "returns a profile_image" do
    expect(described_class.new(user).get.size).to be > 0
  end

  it "renders an error when initializing with a nil object" do
    expect { described_class.new(nil) }.to raise_error(NoMethodError)
  end
end
