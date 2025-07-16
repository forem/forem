require "rails_helper"

RSpec.describe "User searches users" do
  let(:current_user) { create(:user) }
  let(:followed_user) { create(:user) }
  let(:not_followed_user) { create(:user) }
  let(:follow_back_user) { create(:user) }

  before do
    sign_in current_user
    current_user.follow(followed_user)
    follow_back_user.follow(current_user)
    not_followed_user
  end

  xit "shows the correct follow buttons", js: true do
    visit "/search?q=&filters=class_name:User"

    expect(page).to have_css("button.follow-action-button")
    edit_button_info = find_button(I18n.t("core.edit_profile"))['data-info']
    expect(JSON.parse(edit_button_info)["id"]).to eq(current_user.id)

    expect(page).to have_css("button.follow-action-button")
    following_button_info = find_button(I18n.t("core.following"))['data-info']
    expect(JSON.parse(following_button_info)["id"]).to eq(followed_user.id)

    expect(page).to have_css("button.follow-action-button")
    follow_button_info = find_button(I18n.t("core.follow"))['data-info']
    expect(JSON.parse(follow_button_info)["id"]).to eq(not_followed_user.id)

    expect(page).to have_css("button.follow-action-button")
    follow_back_button_info = find_button(I18n.t("core.follow_back"))['data-info']
    expect(JSON.parse(follow_back_button_info)["id"]).to eq(follow_back_user.id)
  end
end