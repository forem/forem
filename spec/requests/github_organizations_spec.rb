require "rails_helper"

RSpec.describe "GithubOrganizations" do
  let(:user) { create(:user, :with_identity, identities: ["github"]) }
  let(:fake_github_client) do
    Class.new(Github::OauthClient) do
      def organization(name); end
    end
  end
  let(:github_client) { instance_double(fake_github_client, organization: { login: "necoz-oss" }) }
  let(:headers) { { Accept: "application/json", "Content-Type": "application/json" } }

  before do
    omniauth_mock_github_payload
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    allow(Github::OauthClient).to receive(:new).and_return(github_client)
  end

  describe "POST /github_organizations" do
    it "returns unauthorized if the user is not signed in" do
      post github_organizations_path, params: { organization: "necoz-oss" }.to_json, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "raises if the user has not authenticated through GitHub" do
      sign_in create(:user)

      expect do
        post github_organizations_path, params: { organization: "necoz-oss" }.to_json, headers: headers
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    context "when the user is authorized" do
      before { sign_in user }

      it "adds the organization" do
        post github_organizations_path, params: { organization: " necoz-oss " }.to_json, headers: headers

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["organizations"]).to eq(%w[necoz-oss])
        expect(user.setting.reload.github_organizations).to eq(%w[necoz-oss])
      end

      it "returns not found and does not save organizations that do not exist on GitHub" do
        allow(github_client).to receive(:organization).and_raise(Github::Errors::NotFound)

        post github_organizations_path, params: { organization: "nope" }.to_json, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(user.setting.reload.github_organizations).to be_empty
      end

      it "rejects invalid usernames without calling GitHub" do
        post github_organizations_path, params: { organization: "not valid!" }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(github_client).not_to have_received(:organization)
      end

      it "rejects duplicated organizations regardless of case" do
        user.setting.update!(github_organizations: %w[necoz-oss])

        post github_organizations_path, params: { organization: "Necoz-OSS" }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects more organizations than the maximum" do
        user.setting.update!(github_organizations: %w[one two three])

        post github_organizations_path, params: { organization: "four" }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to include("up to 3")
      end

      it "returns service unavailable on temporary GitHub failures" do
        allow(github_client).to receive(:organization).and_raise(Github::Errors::ServerError)

        post github_organizations_path, params: { organization: "necoz-oss" }.to_json, headers: headers

        expect(response).to have_http_status(:service_unavailable)
      end

      it "returns unauthorized if the GitHub token cannot be used" do
        allow(github_client).to receive(:organization).and_raise(Github::Errors::Unauthorized)

        post github_organizations_path, params: { organization: "necoz-oss" }.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /github_organizations/:id" do
    before do
      sign_in user
      user.setting.update!(github_organizations: %w[necoz-oss other])
    end

    it "removes the organization" do
      delete github_organization_path("necoz-oss"), headers: headers

      expect(response).to have_http_status(:ok)
      expect(user.setting.reload.github_organizations).to eq(%w[other])
    end

    it "unpins the repositories of the removed organization only" do
      org_repo = create(:github_repo, user: user, info_hash: { owner: { login: "necoz-oss" } })
      other_repo = create(:github_repo, user: user, info_hash: { owner: { login: "other" } })

      delete github_organization_path("necoz-oss"), headers: headers

      expect(GithubRepo.exists?(org_repo.id)).to be(false)
      expect(GithubRepo.exists?(other_repo.id)).to be(true)
    end

    it "returns not found for organizations that were not added" do
      delete github_organization_path("unknown"), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
