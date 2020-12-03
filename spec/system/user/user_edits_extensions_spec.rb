require "rails_helper"

RSpec.describe "User edits their extensions", type: :system, js: true do
  let(:user) { create(:user) }
  let(:github_response_body) do
    [
      {
        "id" => 1_296_269,
        "node_id" => "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
        "name" => "Hello-World",
        "full_name" => "octocat/Hello-World"
      },
    ]
  end

  before do
    sign_in user
    stub_request(:get, "https://api.github.com/user/repos?per_page=100")
      .to_return(status: 200, body: github_response_body.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "Stackbit" do
    before do
      visit user_settings_path
    end

    it "has connect-to-stackbit prompt" do
      click_link "Extensions"

      expect(page).to have_text("Connect to Stackbit")
    end

    it "has connected-to-stackbit prompt if already integrated" do
      create(:doorkeeper_access_token, resource_owner: user)

      click_link "Extensions"
      expect(page).to have_text("Connected to Stackbit")
    end
  end

  describe "Feed" do
    before do
      visit user_settings_path(:extensions)
    end

    it "fails if the feed URL is invalid" do
      stub_request(:get, "https://medium.com/feed/alkdmksadksa")
        .to_return(status: 200, body: "not an xml feed")

      fill_in "user[feed_url]", with: "https://medium.com/feed/alkdmksadksa"
      click_on "Submit Feed Settings"

      expect(page).to have_text("Feed url is not a valid RSS/Atom feed")
    end
  end
end
