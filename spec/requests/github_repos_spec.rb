require "rails_helper"

RSpec.describe "GithubRepos", type: :request do
  let(:user) { create(:user, :with_identity, identities: ["github"]) }
  let(:repo) { build(:github_repo, user: user) }
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
    omniauth_mock_github_payload

    allow(Octokit::Client).to receive(:new).and_return(my_octokit_client)
    allow(my_octokit_client).to receive(:repositories) { stubbed_github_repos }
    allow(my_octokit_client).to receive(:repository) { stubbed_github_repos.first }
  end

  describe "GET /github_repos" do
    context "when user is unauthorized" do
      it "returns unauthorized if the user is not signed in" do
        get github_repos_path, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns unauthorized if the user not has authenticated through GitHub" do
        user = create(:user)
        sign_in user

        expect do
          get github_repos_path, headers: headers
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is authorized" do
      before { sign_in user }

      it "returns unauthorized if the user is not authorized to perform the GitHub API call" do
        allow(Octokit::Client).to receive(:new).and_raise(Octokit::Unauthorized)

        get github_repos_path, headers: headers
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to include("GitHub Unauthorized")
      end

      it "returns 200 on success" do
        get github_repos_path, headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "returns repositories with the correct JSON representation" do
        get github_repos_path, headers: headers

        response_repo = response.parsed_body.first
        expect(response_repo["name"]).to eq(repo.name)
        expect(response_repo["fork"]).to eq(repo.fork)
        expect(response_repo["featured"]).to be(false)
      end
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

    it "returns 404 if no repository is found" do
      allow(my_octokit_client).to receive(:repository).and_raise(Octokit::NotFound)

      params = { github_repo: github_repo.to_json }
      post update_or_create_github_repos_path(params), headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "updates the current user github_repos_updated_at" do
      previous_date = user.github_repos_updated_at

      Timecop.travel(5.minutes.from_now) do
        params = { github_repo: github_repo.to_json }
        post update_or_create_github_repos_path(params), headers: headers
        expect(user.reload.github_repos_updated_at.to_i > previous_date.to_i).to be(true)
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
