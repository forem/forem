require "rails_helper"

RSpec.describe NotificationsHelper, type: :helper do
  it "returns a category image" do
    expect(helper.reaction_image("heart")).to eq("heart-filled.svg")
  end
end
