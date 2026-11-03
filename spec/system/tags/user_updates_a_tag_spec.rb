require "rails_helper"

RSpec.describe "User updates a tag" do
  let(:super_admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }
  let(:tag_moderator) { create(:user, :without_profile, profile_image: nil) }
  let(:bg_color_hex) { "#000000" }
  let(:tag) { create(:tag) }

  def assert_default_and_preserved_bg_color
    visit edit_tag_path(tag.name)
    click_on(I18n.t("views.tags.edit.form.submit"))
    expect(tag.reload.bg_color_hex).to eq(bg_color_hex)

    tag.update!(bg_color_hex: "#0000ff")
    visit edit_tag_path(tag.name)
    click_on(I18n.t("views.tags.edit.form.submit"))
    expect(tag.reload.bg_color_hex).to eq("#0000ff")
  end

  describe "Update tag as a super_admin" do
    it "defaults unset color to black and preserves an existing color", :aggregate_failures do
      sign_in super_admin
      assert_default_and_preserved_bg_color
    end
  end

  describe "Update tag as a tag_moderator" do
    it "defaults unset color to black and preserves an existing color", :aggregate_failures do
      tag_moderator.add_role(:tag_moderator, tag)
      sign_in tag_moderator
      assert_default_and_preserved_bg_color
    end
  end
end
