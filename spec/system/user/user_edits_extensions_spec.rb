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

  describe "via visiting /settings" do
    before do
      visit "/settings"
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
end
