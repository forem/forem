require "rails_helper"

RSpec.describe "Api::V0::GithubRepos", type: :request do
  let(:user) { create(:user) }
  let(:repo) { build(:github_repo, user: user) }
  let(:my_ocktokit_client) { instance_double(Octokit::Client) }
  let(:stubbed_github_repos) do
    [OpenStruct.new(repo.attributes.merge(id: repo.github_id_code, html_url: Faker::Internet.url))]
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(my_ocktokit_client)
    allow(my_ocktokit_client).to receive(:repositories) { stubbed_github_repos }
    sign_in user
  end

  describe "GET /api/v0/github_repos" do
    it "returns 200 on success" do
      get "/api/github_repos"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v0/github_repos/update_or_create" do
    it "returns 200 and json response on success" do
      param = stubbed_github_repos.first.to_h.to_json
      post "/api/github_repos/update_or_create", params: { github_repo: param }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/json")
    end
  end
end
