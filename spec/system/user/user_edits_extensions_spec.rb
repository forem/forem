require "rails_helper"

RSpec.describe "User edits their extensions", js: true do
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

  # Feed settings have been moved to /dashboard/feed_imports
  # See spec/requests/feeds/sources_spec.rb for feed source CRUD tests
end
