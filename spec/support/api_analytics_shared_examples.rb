RSpec.shared_examples "GET /api/analytics/:endpoint authorization examples" do |endpoint, params|
  let(:user)              { create(:user) }
  let(:api_token)         { create(:api_secret, user: user) }
  let(:org)               { create(:organization) }
  let(:pro_user)          { create(:user, :pro) }
  let(:pro_api_token)     { create(:api_secret, user: pro_user) }
  let(:pro_org_member)    { create(:user, :pro, :org_member) }
  let(:org_member_token)  { create(:api_secret, user: pro_org_member) }

  context "when an invalid token is given" do
    before { get "/api/analytics/#{endpoint}?#{params}", headers: { "HTTP_API_KEY" => "abadskajdlsak" } }

    it "renders an error message: 'Not authorized' in JSON" do
      expect(JSON.parse(response.body)["error"]).to eq "Not authorized"
    end

    it "has a status 401" do
      expect(response.status).to eq 401
    end
  end

  context "when a valid token is given but the user is not a pro" do
    before { get "/api/analytics/#{endpoint}?#{params}", headers: { "HTTP_API_KEY" => "abadskajdlsak" } }

    it "renders an error message: 'Not authorized' in JSON" do
      expect(JSON.parse(response.body)["error"]).to eq "Not authorized"
    end

    it "has a status 401" do
      expect(response.status).to eq 401
    end
  end

  context "when a valid token is given and the user is a pro" do
    before { get "/api/analytics/#{endpoint}?#{params}", headers: { "HTTP_API_KEY" => pro_api_token.secret } }

    it "renders JSON as the content type" do
      expect(response.content_type).to eq "application/json"
    end
  end

  context "when attempting to view organization analytics without belonging to the organization" do
    before do
      get "/api/analytics/#{endpoint}?organization_id=#{org.id}#{params}", headers: { "HTTP_API_KEY" => pro_api_token.secret }
    end

    it "renders an error message: 'Not authorized' in JSON" do
      expect(JSON.parse(response.body)["error"]).to eq "Not authorized"
    end

    it "has a status 401" do
      expect(response.status).to eq 401
    end
  end

  context "when attempting to view organization analytics and being a member of the organization" do
    before do
      get "/api/analytics/#{endpoint}?organization_id=#{pro_org_member.organization_id}#{params}", headers: { "HTTP_API_KEY" => org_member_token.secret }
    end

    it "renders JSON as the content type" do
      expect(response.content_type).to eq "application/json"
    end
  end

  context "when attempting to view another organization analytics and not belonging to that organization" do
    it "responds with status 401 unauthorized" do
      org = create(:organization)
      get "/api/analytics/#{endpoint}?organization_id=#{org.id}#{params}", headers: { "HTTP_API_KEY" => org_member_token.secret }
      expect(response.status).to eq 401
    end
  end
end
