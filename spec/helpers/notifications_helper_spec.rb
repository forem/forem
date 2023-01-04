require "rails_helper"

RSpec.describe NotificationsHelper do
  it "returns a category image" do
    expect(helper.reaction_image("unicorn")).to eq("unicorn-filled.svg")
  end
end
