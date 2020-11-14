require "rails_helper"

RSpec.describe ReactionImage, type: :labor do
  it "returns a category image" do
    expect(described_class.new("unicorn").path).to eq("unicorn-filled.svg")
  end
end
