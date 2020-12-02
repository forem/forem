require "rails_helper"

RSpec.describe "GithubRepos", type: :request do
  let(:fake_github_client) do
    Class.new(Github::OauthClient) do
      def repositories(*_args); end

      def repository(name); end
    end
  end
  let(:user) { create(:user, :with_identity, identities: ["github"]) }
  # Using explicit name attributes soordering in controller is stable
  let(:repo1) { build(:github_repo, user: user, name: "A", featured: false) }
  let(:repo2) { build(:github_repo, user: user, name: "B", featured: true) }
  let(:stubbed_github_repos) do
    repo1_params = repo1.attributes.merge(
      id: repo1.github_id_code,
      html_url: Faker::Internet.url,
    )

    repo2_params = repo2.attributes.merge(
      id: repo2.github_id_code,
      html_url: Faker::Internet.url,
    )

    [OpenStruct.new(repo1_params), OpenStruct.new(repo2_params)] # rubocop:disable Performance/OpenStruct
  end
  let(:github_client) do
    instance_double(
      fake_github_client,
      repositories: stubbed_github_repos,
      repository: stubbed_github_repos.first,
    )
  end
  let(:headers) do
    {
      Accept: "application/json",
      "Content-Type": "application/json"
    }
  end

  before do
    omniauth_mock_github_payload
    allow(SiteConfig).to receive(:authentication_providers).and_return(Authentication::Providers.available)
    allow(Github::OauthClient).to receive(:new).and_return(github_client)
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
        allow(Github::OauthClient).to receive(:new).and_raise(Github::Errors::Unauthorized)

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

        response_repo1, response_repo2 = response.parsed_body
        expect(response_repo1["name"]).to eq(repo1.name)
        expect(response_repo1["fork"]).to eq(repo1.fork)
        expect(response_repo1["featured"]).to be(false)
        expect(response_repo2["name"]).to eq(repo2.name)
        expect(response_repo2["fork"]).to eq(repo2.fork)
        expect(response_repo2["featured"]).to be(true)
      end

      it "deletes repositories which are no longer publicly accessible" do
        deleted_repo = create(:github_repo, user: user, featured: true)

        expect do
          get github_repos_path, headers: headers
        end.to change { GithubRepo.find_by(id: deleted_repo.id) }.from(deleted_repo).to(nil)
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
      expect(response.media_type).to eq("application/json")
    end

    it "returns 404 if no repository is found" do
      allow(github_client).to receive(:repository).and_raise(Github::Errors::NotFound)

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
