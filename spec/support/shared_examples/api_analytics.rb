RSpec.shared_examples "GET /api/analytics/:endpoint authorization examples" do |endpoint, params|
  let(:user)              { create(:user, :without_profile, profile_image: nil) }
  let(:api_token)         { create(:api_secret, user: user) }
  let(:org)               { create(:organization) }
  let(:org_member) do
    create(:user, :without_profile, profile_image: nil).tap do |member|
      create(:organization_membership, user: member, organization: org, type_of_user: "member")
    end
  end
  let(:org_member_token)  { create(:api_secret, user: org_member) }
  let(:article)           { create(:article, user: user, with_tags: false) }
  let(:user_article)      { article }
  let(:org_article)       { create(:article, user: user, organization: org, with_tags: false) }

  context "when an invalid token is given" do
    before { get "/api/analytics/#{endpoint}?#{params}", headers: { "api-key" => "abadskajdlsak" } }

    it "returns 401 with an unauthorized error message in JSON", :aggregate_failures do
      expect(response.parsed_body).to include("error" => "unauthorized")
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when a valid token is given" do
    before { get "/api/analytics/#{endpoint}?#{params}", headers: { "api-key" => api_token.secret } }

    it "renders JSON as the content type" do
      expect(response.media_type).to eq "application/json"
    end
  end

  context "when attempting to view organization analytics without belonging to the organization" do
    before do
      headers = { "api-key" => api_token.secret }
      get "/api/analytics/#{endpoint}?organization_id=#{org.id}#{params}", headers: headers
    end

    it "returns 401 with an unauthorized error message in JSON", :aggregate_failures do
      expect(response.parsed_body).to include("error" => "unauthorized")
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when attempting to view organization analytics and being a member of the organization" do
    before do
      path = "/api/analytics/#{endpoint}?organization_id=#{org_member.organization_ids.first}#{params}"
      get path, headers: { "api-key" => org_member_token.secret }
    end

    it "renders JSON as the content type" do
      expect(response.media_type).to eq "application/json"
    end
  end

  context "when attempting to view another organization analytics and not belonging to that organization" do
    it "responds with status 401 unauthorized" do
      org = create(:organization)
      headers = { "api-key" => org_member_token.secret }
      get "/api/analytics/#{endpoint}?organization_id=#{org.id}#{params}", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when attempting to view someone else's article analytics" do
    it "responds with status 401 unauthorized" do
      get "/api/analytics/#{endpoint}?article_id=#{article.id}#{params}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when viewing as current user" do
    it "responds with status 200 OK" do
      sign_in user
      get "/api/analytics/#{endpoint}?#{params}"
      expect(response).to have_http_status(:ok)
    end
  end

  context "when viewing your own single article's analytics" do
    it "responds with status 200 OK" do
      sign_in user
      get "/api/analytics/#{endpoint}?article_id=#{user_article.id}#{params}"
      expect(response).to have_http_status(:ok)
    end
  end

  context "when viewing your own organization's single article's analytics" do
    it "responds with status 200 OK" do
      org_param = "&organization_id=#{org_article.organization.id}"

      sign_in org_member
      get "/api/analytics/#{endpoint}?article_id=#{org_article.id}#{params}#{org_param}"
      expect(response).to have_http_status(:ok)
    end
  end
end
