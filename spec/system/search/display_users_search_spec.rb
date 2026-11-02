require "rails_helper"

RSpec.describe "Display users search spec", :js do
  let(:current_user) { create(:user, :without_profile, profile_image: nil, username: "ironman", name: "Iron Man") }
  let(:found_user) { create(:user, :without_profile, username: "janedoe", name: "Jane Doe") }
  let(:found_two_user) { create(:user, :without_profile, profile_image: nil, username: "doejane", name: "Doe Jane") }
  let(:not_found_user) { create(:user, :without_profile, profile_image: nil, username: "batman", name: "Batman") }

  it "returns correct results and user fields for name search", :aggregate_failures do
    current_user
    found_user
    found_two_user
    not_found_user
    visit "/search?q=jane&filters=class_name:User"

    expect(page).to have_content(found_user.name)
    expect(page).to have_content(found_two_user.name)
    expect(page).to have_no_content(current_user.name)
    expect(page).to have_no_content(not_found_user.name)

    expect(find(:xpath, "//img[@alt='#{found_user.username} profile']")["src"]).to include(found_user.profile_image_90)
    follow_button_info = find("#article-#{found_user.id} button.follow-action-button")["data-info"]
    expect(JSON.parse(follow_button_info)["id"]).to eq(found_user.id)
  end
end
