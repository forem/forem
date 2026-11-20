require "rails_helper"

RSpec.describe "Admin updates a tag" do
  let(:super_admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }
  let(:bg_color_hex) { "#000000" }

  before do
    sign_in super_admin
  end

  context "when no colors have been chosen for the tag" do
    let(:tag) { create(:tag) }

    before do
      visit edit_admin_tag_path(tag.id)
    end

    it "allows an Admin to update a tag and defaults to black and white", :aggregate_failures do
      expect(page).to have_content("Edit details")
      check("Supported")
      click_on("Update Tag")

      expect(tag.reload.bg_color_hex).to eq(bg_color_hex)
      expect(page).to have_current_path(edit_admin_tag_path(tag.id))
      expect(page).to have_content("#{tag.name} tag successfully updated!")
    end
  end

  context "when colors have already been chosen for the tag" do
    let(:tag) { create(:tag, bg_color_hex: "#0000ff") }

    before do
      visit edit_admin_tag_path(tag.id)
    end

    it "remains the same color it was unless otherwise updated via the color picker", :aggregate_failures do
      old_bg_color_hex = tag.bg_color_hex

      click_on("Update Tag")

      expect(tag.reload.bg_color_hex).to eq(old_bg_color_hex)
      expect(page).to have_current_path(edit_admin_tag_path(tag.id))
      expect(page).to have_content("#{tag.name} tag successfully updated!")
    end
  end
end
