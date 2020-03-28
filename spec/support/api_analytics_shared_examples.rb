RSpec.shared_examples "GET /api/analytics/:endpoint authorization examples" do |endpoint, params|
  let(:user)              { create(:user) }
  let(:api_token)         { create(:api_secret, user: user) }
  let(:org)               { create(:organization) }
  let(:pro_user)          { create(:user, :pro) }
  let(:pro_api_token)     { create(:api_secret, user: pro_user) }
  let(:pro_org_member)    { create(:user, :pro, :org_member) }
  let(:org_member_token)  { create(:api_secret, user: pro_org_member) }
  let(:article)           { create(:article, user: user) }
  let(:pro_user_article)  { create(:article, user: pro_user) }
  let(:pro_org_article)   { create(:article, user: pro_user, organization: org) }

  context "when an invalid token is given" do
    before { get "/api/analytics/#{endpoint}?#{params}", headers: { "api-key" => "abadskajdlsak" } }

    it "renders an error message: 'unauthorized' in JSON" do
      expect(JSON.parse(response.body)["error"]).to eq "unauthorized"
    end

    it "has a status 401" do
      expect(response.status).to eq 401
    end
  end

  context "when a valid token is given but the user is not a pro" do
    before { get "/api/analytics/#{endpoint}?#{params}", headers: { "api-key" => api_token.secret } }

    it "renders an error message: 'unauthorized' in JSON" do
      expect(JSON.parse(response.body)["error"]).to eq "unauthorized"
    end

    it "has a status 401" do
      expect(response.status).to eq 401
    end
  end

  context "when a valid token is given and the user is a pro" do
    before { get "/api/analytics/#{endpoint}?#{params}", headers: { "api-key" => pro_api_token.secret } }

    it "renders JSON as the content type" do
      expect(response.content_type).to eq "application/json"
    end
  end

  context "when attempting to view organization analytics without belonging to the organization" do
    before do
      get "/api/analytics/#{endpoint}?organization_id=#{org.id}#{params}", headers: { "api-key" => pro_api_token.secret }
    end

    it "renders an error message: 'unauthorized' in JSON" do
      expect(JSON.parse(response.body)["error"]).to eq "unauthorized"
    end

    it "has a status 401" do
      expect(response.status).to eq 401
    end
  end

  context "when attempting to view organization analytics and being a member of the organization" do
    before do
      path = "/api/analytics/#{endpoint}?organization_id=#{pro_org_member.organization_ids.first}#{params}"
      get path, headers: { "api-key" => org_member_token.secret }
    end

    it "renders JSON as the content type" do
      expect(response.content_type).to eq "application/json"
    end
  end

  context "when attempting to view another organization analytics and not belonging to that organization" do
    it "responds with status 401 unauthorized" do
      org = create(:organization)
      get "/api/analytics/#{endpoint}?organization_id=#{org.id}#{params}", headers: { "api-key" => org_member_token.secret }
      expect(response.status).to eq 401
    end
  end

  context "when attempting to view someone else's article analytics" do
    it "responds with status 401 unauthorized" do
      get "/api/analytics/#{endpoint}?article_id=#{article.id}#{params}"
      expect(response.status).to eq 401
    end
  end

  context "when viewing as current user" do
    it "responds with status 200 OK" do
      sign_in pro_user
      get "/api/analytics/#{endpoint}?#{params}"
      expect(response.status).to eq 200
    end
  end

  context "when viewing your own single article's analytics" do
    it "responds with status 200 OK" do
      sign_in pro_user
      get "/api/analytics/#{endpoint}?article_id=#{pro_user_article.id}#{params}"
      expect(response.status).to eq 200
    end
  end

  context "when viewing your own organizaiton's single article's analytics" do
    it "responds with status 200 OK" do
      sign_in pro_org_member
      get "/api/analytics/#{endpoint}?article_id=#{pro_org_article.id}#{params}"
    end
  end
end
