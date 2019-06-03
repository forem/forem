require "rails_helper"

RSpec.describe "User edits their integrations", type: :system, js: true do
  let(:user) { create(:user, saw_onboarding: true) }
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
    stub_request(:get, "https://api.github.com/user/repos?per_page=100").to_return(status: 200, body: github_response_body.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "via visiting /settings" do
    it "and sets a Twitch Username" do
      visit "/settings"
      expect(page).to have_current_path("/settings")

      click_link "Integrations"

      fill_in "Twitch Username", with: "TestTwitchUser"
      click_button("SUBMIT")

      expect(page).to have_content "Your Twitch username was successfully updated."

      visit "/settings/integrations"
      expect(find_field("Twitch Username").value).to eq "TestTwitchUser"
    end
  end
end
