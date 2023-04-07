require "rails_helper"

RSpec.describe NotificationsHelper do
  it "returns a new category image from ReactionCategory" do
    expect(helper.reaction_image("unicorn")).to eq("multi-unicorn.svg")
  end

  it "returns a heart for unrecognized category" do
    expect(helper.reaction_image("asdf")).to eq("sparkle-heart.svg")
  end
end
