require "rails_helper"

RSpec.describe "GithubRepos", type: :request do
  let(:user) { create(:user, :with_identity, identities: ["github"]) }
  let(:repo) { build(:github_repo, user_id: user.id) }
  let(:my_octokit_client) { instance_double(Octokit::Client) }
  let(:stubbed_github_repos) do
    repo_params = repo.attributes.merge(
      id: repo.github_id_code,
      html_url: Faker::Internet.url,
    )
    [OpenStruct.new(repo_params)]
  end
  let(:headers) do
    {
      Accept: "application/json",
      "Content-Type": "application/json"
    }
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(my_octokit_client)
    allow(my_octokit_client).to receive(:repositories) { stubbed_github_repos }
  end

  describe "GET /github_repos" do
    context "when user is unauthorized" do
      it "returns unauthorized" do
        get github_repos_path, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authorized" do
      before { sign_in user }

      it "returns 200 on success" do
        get github_repos_path, headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "returns 401 if github raises an unauthorized error" do
        allow(Octokit::Client).to receive(:new).and_raise(Octokit::Unauthorized)

        get github_repos_path, headers: headers
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to include("Github Unauthorized")
      end

      it "returns repos with the correct json representation" do
        get github_repos_path, headers: headers

        response_repo = response.parsed_body.first
        expect(response_repo["name"]).to eq(repo.name)
        expect(response_repo["fork"]).to eq(repo.fork)
        expect(response_repo["selected"]).to be(false)
      end
    end
  end

  describe "POST /github_repos" do
    before { sign_in user }

    it "returns a 302" do
      params = { github_repo: { github_id_code: repo.github_id_code } }
      post github_repos_path, params: params

      expect(response).to have_http_status(:found)
    end

    it "creates a new GithubRepo object" do
      params = { github_repo: { github_id_code: repo.github_id_code } }
      expect do
        post github_repos_path, params: params
      end.to change(GithubRepo, :count).by(1)
    end
  end

  describe "PUT /github_repos/:id" do
    before do
      repo.save
      sign_in user
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

  describe "POST /github_repos/update_or_create" do
    before { sign_in user }

    let(:github_repo) { stubbed_github_repos.first.to_h }

    it "returns 200 and json response on success" do
      params = { github_repo: github_repo.to_json }
      post update_or_create_github_repos_path(params), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/json")
    end

    it "returns 404 and json response on error" do
      allow(my_octokit_client).to receive(:repositories).and_return([])

      params = { github_repo: "{}" }
      post update_or_create_github_repos_path(params), headers: headers
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Could not find Github repo")
    end

    it "updates the current user github_repos_updated_at" do
      previous_date = user.github_repos_updated_at

      Timecop.travel(5.minutes.from_now) do
        params = { github_repo: github_repo.to_json }
        post update_or_create_github_repos_path(params), headers: headers
        expect(user.reload.github_repos_updated_at > previous_date).to be(true)
      end
    end

    it "allows the repo to be featured" do
      github_repo[:featured] = true
      params = { github_repo: github_repo.to_json }
      post update_or_create_github_repos_path(params), headers: headers

      expect(response.parsed_body["featured"]).to be(true)
    end

    it "allows the repo to be unfeatured" do
      github_repo[:featured] = false
      params = { github_repo: github_repo.to_json }
      post update_or_create_github_repos_path(params), headers: headers

      expect(response.parsed_body["featured"]).to be(false)
    end
  end
end
