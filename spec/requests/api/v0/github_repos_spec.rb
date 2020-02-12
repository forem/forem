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
      get api_github_repos_path

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 if github raises an unauthorized error" do
      allow(Octokit::Client).to receive(:new).and_raise(Octokit::Unauthorized)

      get api_github_repos_path
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to include("Github Unauthorized")
    end

    it "returns repos with the correct json representation" do
      get api_github_repos_path

      response_repo = response.parsed_body.first
      expect(response_repo["name"]).to eq(repo.name)
      expect(response_repo["fork"]).to eq(repo.fork)
      expect(response_repo["selected"]).to be(false)
    end
  end

  describe "POST /api/v0/github_repos/update_or_create" do
    it "returns 200 and json response on success" do
      param = stubbed_github_repos.first.to_h.to_json
      post update_or_create_api_github_repos_path(github_repo: param)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/json")
    end

    it "returns 404 and json response on error" do
      allow(Octokit::Client).to receive(:new).and_return(my_ocktokit_client)
      allow(my_ocktokit_client).to receive(:repositories).and_return([])

      post update_or_create_api_github_repos_path(github_repo: "{}")
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Could not find Github repo")
    end
  end
end
