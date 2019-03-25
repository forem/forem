require "rails_helper"

RSpec.describe "GithubRepos", type: :request do
  let(:user) { create(:user) }
  let(:repo) { build(:github_repo, user_id: user.id) }
  let(:my_ocktokit_client) { instance_double(Octokit::Client) }
  let(:stubbed_github_repos) do
    [OpenStruct.new(repo.attributes.merge(id: repo.github_id_code, html_url: Faker::Internet.url))]
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(my_ocktokit_client)
    allow(my_ocktokit_client).to receive(:repositories) { stubbed_github_repos }
    sign_in user
  end

  describe "POST /github_repos" do
    it "returns a 302" do
      post "/github_repos", params: { github_repo: { github_id_code: repo.github_id_code } }
      expect(response).to have_http_status(:found)
    end

    it "creates a new GithubRepo object" do
      post "/github_repos", params: { github_repo: { github_id_code: repo.github_id_code } }
      expect(GithubRepo.count).to eq(1)
    end
  end

  describe "PUT /github_repos/:id" do
    before do
      repo.save
    end

    it "returns a 302" do
      put "/github_repos/#{repo.id}"
      expect(response).to have_http_status(:found)
    end

    it "unfeatures the requested GithubRepo" do
      put "/github_repos/#{repo.id}"
      expect(GithubRepo.first.featured).to eq(false)
    end
  end
end
