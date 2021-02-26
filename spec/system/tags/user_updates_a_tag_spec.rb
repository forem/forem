require "rails_helper"

RSpec.describe "User updates a tag", type: :system do
  let(:super_admin) { create(:user, :super_admin) }
  let(:tag_moderator) { create(:user) }
  let(:tag) { create(:tag) }

  describe "UPDATE /t/:tag/edit as a super_admin" do
    context "when no colors have been choosen for the tag" do
      before do
        sign_in super_admin
        visit "/t/#{tag}/edit"
      end

      it "defaults to white text for the color picker" do
        expect(page).to have_field("tag_text_color_hex", with: "#ffffff")
      end

      it "defaults to black and white upon update", :aggregate_failures do
        click_button("SAVE CHANGES")
        tag.reload
        expect(tag.bg_color_hex).to eq("#000000")
        expect(tag.text_color_hex).to eq("#ffffff")
      end
    end

    context "when colors have already been choosen for the tag" do
      before do
        sign_in super_admin
        visit "/t/#{tag}/edit"
      end

      it "remains the same color it was unless otherwise updated via the color picker", :aggregate_failures do
        click_button("SAVE CHANGES")
        expect(tag.bg_color_hex).to eq(tag.bg_color_hex)
        expect(tag.text_color_hex).to eq(tag.text_color_hex)
      end
    end
  end

  describe "UPDATE /t/:tag/edit as a tag_moderator" do
    context "when no colors have been choosen for the tag" do
      before do
        tag_moderator.add_role(:tag_moderator, tag)
        sign_in tag_moderator
        visit "/t/#{tag}/edit"
      end

      it "defaults to white text for the color picker" do
        expect(page).to have_field("tag_text_color_hex", with: "#ffffff")
      end

      it "defaults to black and white upon update", :aggregate_failures do
        click_button("SAVE CHANGES")
        tag.reload
        expect(tag.bg_color_hex).to eq("#000000")
        expect(tag.text_color_hex).to eq("#ffffff")
      end
    end

    context "when colors have already been choosen for the tag" do
      before do
        tag_moderator.add_role(:tag_moderator, tag)
        sign_in tag_moderator
        visit "/t/#{tag}/edit"
      end

      it "remains the same color it was unless otherwise updated via the color picker", :aggregate_failures do
        click_button("SAVE CHANGES")
        expect(tag.bg_color_hex).to eq(tag.bg_color_hex)
        expect(tag.text_color_hex).to eq(tag.text_color_hex)
      end
    end
  end
end
