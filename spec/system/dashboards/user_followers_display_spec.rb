require "rails_helper"

RSpec.describe "Followers Dashboard", type: :system, js: true do
  let(:default_per_page) { 3 }
  let(:user) { create(:user) }
  let(:followed_user) { create(:user) }
  let(:following_user) { create(:user) }

  before do
    sign_in user
  end

  context "when /dashboard/user_followers is visited" do
    xit "displays correct following buttons" do
      following_user.follow(user)
      followed_user.follow(user)
      user.follow(followed_user)
      visit "/dashboard/user_followers"

      expect(JSON.parse(find_button(I18n.t("core.following"))["data-info"])["id"]).to eq(followed_user.id)
      expect(JSON.parse(find_button(I18n.t("core.follow_back"))["data-info"])["id"]).to eq(following_user.id)
    end
  end
end
