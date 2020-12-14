require "rails_helper"

RSpec.describe "Admin updates a tag", type: :system do
  let(:super_admin) { create(:user, :super_admin) }
  let(:tag) { create(:tag) }

  context "when no colors have been choosen for the tag" do
    before do
      sign_in super_admin
      visit edit_admin_tag_path(tag.id)
    end

    it "defaults to white text for the color picker" do
      expect(page).to have_field("tag_text_color_hex", with: "#ffffff")
    end

    it "defaults to black and white upon update" do
      check "Supported"
      click_button("Update Tag")
      tag.reload
      expect(tag.bg_color_hex).to eq("#000000")
      expect(tag.text_color_hex).to eq("#ffffff")
    end
  end

  context "when colors have already been choosen for the tag" do
    before do
      sign_in super_admin
      visit edit_admin_tag_path(tag)
    end

    it "remains the same color it was unless otherwise updated via the color picker" do
      click_button("Update Tag")
      expect(tag.bg_color_hex).to eq(tag.bg_color_hex)
      expect(tag.text_color_hex).to eq(tag.text_color_hex)
    end
  end
end
