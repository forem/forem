require "rails_helper"

RSpec.describe "User updates a tag", type: :system do
  let(:super_admin) { create(:user, :super_admin) }
  let(:tag_moderator) { create(:user) }
  let(:bg_color_hex) { "#000000" }
  let(:text_color_hex) { "#ffffff" }

  describe "Update tag as a super_admin" do
    let(:tag) { create(:tag) }

    context "when no colors have been choosen for the tag" do
      before do
        sign_in super_admin
        visit edit_tag_path(tag.name)
      end

      it "defaults to white text for the color picker" do
        expect(page).to have_field("tag_text_color_hex", with: "#ffffff")
      end

      it "defaults to black and white upon update", :aggregate_failures do
        click_button("SAVE CHANGES")

        tag.reload

        expect(tag.bg_color_hex).to eq(bg_color_hex)
        expect(tag.text_color_hex).to eq(text_color_hex)
      end
    end

    context "when colors have already been choosen for the tag" do
      let(:tag) { create(:tag, bg_color_hex: "#0000ff", text_color_hex: "#ff0000") }

      before do
        sign_in super_admin
        visit edit_tag_path(tag.name)
      end

      it "remains the same color it was unless otherwise updated via the color picker", :aggregate_failures do
        old_bg_color_hex = tag.bg_color_hex
        old_text_color_hex = tag.text_color_hex

        click_button("SAVE CHANGES")

        expect(tag.reload.bg_color_hex).to eq(old_bg_color_hex)
        expect(tag.reload.text_color_hex).to eq(old_text_color_hex)
      end
    end
  end

  describe "Update tag as a tag_moderator" do
    let(:tag) { create(:tag) }

    context "when no colors have been choosen for the tag" do
      before do
        tag_moderator.add_role(:tag_moderator, tag)
        sign_in tag_moderator
        visit edit_tag_path(tag.name)
      end

      it "defaults to white text for the color picker" do
        expect(page).to have_field("tag_text_color_hex", with: "#ffffff")
      end

      it "defaults to black and white upon update", :aggregate_failures do
        click_button("SAVE CHANGES")

        tag.reload

        expect(tag.bg_color_hex).to eq(bg_color_hex)
        expect(tag.text_color_hex).to eq(text_color_hex)
      end
    end

    context "when colors have already been choosen for the tag" do
      let(:tag) { create(:tag, bg_color_hex: "#0000ff", text_color_hex: "#ff0000") }

      before do
        tag_moderator.add_role(:tag_moderator, tag)
        sign_in tag_moderator
        visit edit_tag_path(tag.name)
      end

      it "remains the same color it was unless otherwise updated via the color picker", :aggregate_failures do
        old_bg_color_hex = tag.bg_color_hex
        old_text_color_hex = tag.text_color_hex

        click_button("SAVE CHANGES")

        expect(tag.reload.bg_color_hex).to eq(old_bg_color_hex)
        expect(tag.reload.text_color_hex).to eq(old_text_color_hex)
      end
    end
  end
end
