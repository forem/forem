require "rails_helper"

RSpec.describe NotificationsHelper do
  context "when feature flag enabled" do
    before { allow(FeatureFlag).to receive(:enabled?).with(:multiple_reactions).and_return(true) }

    it "returns a new category image from ReactionCategory" do
      expect(helper.reaction_image("unicorn")).to eq("multi-unicorn.svg")
    end

    it "returns a heart for unrecognized category" do
      expect(helper.reaction_image("asdf")).to eq("sparkle-heart.svg")
    end
  end

  context "when feature flag disabled" do
    before { allow(FeatureFlag).to receive(:enabled?).with(:multiple_reactions).and_return(false) }

    it "returns an original category image from REACTION_IMAGES" do
      expect(helper.reaction_image("unicorn")).to eq("unicorn-filled.svg")
    end

    it "returns a heart for unrecognized category" do
      expect(helper.reaction_image("asdf")).to eq("heart-filled.svg")
    end
  end
end
