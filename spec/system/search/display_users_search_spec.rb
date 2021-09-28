require "rails_helper"

RSpec.describe "Display users search spec", type: :system, js: true do
  let(:current_user) { create(:user, username: "ironman", name: "Iron Man") }
  let(:found_user) { create(:user, username: "janedoe", name: "Jane Doe") }
  let(:found_two_user) { create(:user, username: "doejane", name: "Doe Jane") }
  let(:not_found_user) { create(:user, username: "batman", name: "Batman") }

  it "returns correct results for name search" do
    current_user
    found_user
    found_two_user
    not_found_user
    visit "/search?q=jane&filters=class_name:User"

    expect(page).to have_content(found_user.name)
    expect(page).to have_content(found_two_user.name)
    expect(page).not_to have_content(current_user.name)
    expect(page).not_to have_content(not_found_user.name)
  end

  it "returns all expected user fields" do
    current_user
    found_user
    sign_in current_user
    visit "/search?q=jane&filters=class_name:User"

    expect(page).to have_content(found_user.name)
    expect(find("span.crayons-story__flare-tag").text).to have_content("person")
    expect(find(:xpath, "//img[@alt='#{found_user.username} profile']")["src"]).to include(found_user.profile_image_90)
    expect(JSON.parse(find_button(I18n.t("core.follow"))["data-info"])["id"]).to eq(found_user.id)
  end
end
