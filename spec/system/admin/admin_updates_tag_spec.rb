require "rails_helper"

RSpec.describe "Admin updates a tag", type: :system do
  let(:super_admin) { create(:user, :super_admin) }
  let(:bg_color_hex) { "#000000" }
  let(:text_color_hex) { "#ffffff" }

  context "when no colors have been choosen for the tag" do
    let(:tag) { create(:tag) }

    before do
      sign_in super_admin
      visit edit_admin_tag_path(tag.id)
    end

    it "allows an Admin to succesfully update a tag", :aggregate_failures do
      visit edit_admin_tag_path(tag.id)
      expect(page).to have_content("Edit details")
      check "Supported"
      click_on("Update Tag")
      expect(page).to have_current_path(edit_admin_tag_path(tag.id))
      expect(page).to have_content("#{tag.name} tag successfully updated!")
    end

    it "defaults to white text for the color picker" do
      expect(page).to have_field("tag_text_color_hex", with: "#ffffff")
    end

    it "defaults to black and white upon update", :aggregate_failures do
      check("Supported")
      click_button("Update Tag")

      tag.reload

      expect(tag.bg_color_hex).to eq(bg_color_hex)
      expect(tag.text_color_hex).to eq(text_color_hex)
      expect(page).to have_current_path(edit_admin_tag_path(tag.id))
      expect(page).to have_content("#{tag.name} tag successfully updated!")
    end
  end

  context "when colors have already been choosen for the tag" do
    let(:tag) { create(:tag, bg_color_hex: "#0000ff", text_color_hex: "#ff0000") }

    before do
      sign_in super_admin
      visit edit_admin_tag_path(tag.id)
    end

    it "remains the same color it was unless otherwise updated via the color picker", :aggregate_failures do
      old_bg_color_hex = tag.bg_color_hex
      old_text_color_hex = tag.text_color_hex

      click_button("Update Tag")

      expect(tag.reload.bg_color_hex).to eq(old_bg_color_hex)
      expect(tag.reload.text_color_hex).to eq(old_text_color_hex)
      expect(page).to have_current_path(edit_admin_tag_path(tag.id))
      expect(page).to have_content("#{tag.name} tag successfully updated!")
    end
  end
end
