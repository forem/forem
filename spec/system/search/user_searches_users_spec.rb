require "rails_helper"

RSpec.describe "User searches users", type: :system do
  let(:current_user) { create(:user) }
  let(:followed_user) { create(:user) }
  let(:not_followed_user) { create(:user) }
  let(:follow_back_user) { create(:user) }

  before do
    sign_in current_user
    current_user.follow(followed_user)
    follow_back_user.follow(current_user)
    [current_user, followed_user, not_followed_user, follow_back_user].each(&:index_to_elasticsearch_inline)
    Search::User.refresh_index
  end

  it "shows the correct follow buttons", js: true, elasticsearch: "User" do
    stub_request(:post, "http://www.google-analytics.com/collect")
    visit "/search?q=&filters=class_name:User"

    expect(JSON.parse(find_button("Edit profile")["data-info"])["id"]).to eq(current_user.id)
    expect(JSON.parse(find_button("Following")["data-info"])["id"]).to eq(followed_user.id)
    expect(JSON.parse(find_button("Follow")["data-info"])["id"]).to eq(not_followed_user.id)
    expect(JSON.parse(find_button("Follow back")["data-info"])["id"]).to eq(follow_back_user.id)
  end
end
