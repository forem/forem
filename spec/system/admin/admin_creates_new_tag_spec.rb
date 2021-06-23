require "rails_helper"

RSpec.describe "Admin creates new tag", type: :system do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
    visit new_admin_tag_path
  end

  def create_and_publish_tag
    fill_in("Name", with: "Tag Name")
    check "Supported"
    fill_in("Short summary", with: "This is a tag")
    click_button("Create Tag")
  end

  it "creates a new tag", :aggregate_failures do
    expect(page).to have_content("New Tag")
    create_and_publish_tag
    expect(page.driver.status_code).to eq(200)
  end
end
