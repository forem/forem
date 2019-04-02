RSpec.shared_examples "GET /api/analytics/:endpoint authorization examples" do |endpoint, extra_params|
  context "when an invalid token is given" do
    it "raises the ActiveRecord::RecordNotFound error" do
      invalid_token = "abadskajdlsak"
      expect { get "/api/analytics/#{endpoint}?api_token=#{invalid_token}#{extra_params}" }.
        to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "when a valid token is given but the user is not a pro" do
    it "raises the ActiveRecord::RecordNotFound error" do
      expect { get "/api/analytics/#{endpoint}?api_token=#{api_token.secret}#{extra_params}" }.
        to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "when a valid token is given and the user is a pro" do
    before { get "/api/analytics/#{endpoint}?api_token=#{pro_api_token.secret}#{extra_params}" }

    it "renders JSON as the content type" do
      expect(response.content_type).to eq "application/json"
    end
  end

  context "when attempting to view organization analytics without belonging to the organization" do
    it "raises the ActiveRecord::RecordNotFound error" do
      expect { get "/api/analytics/#{endpoint}?api_token=#{pro_api_token.secret}&organization_id=#{org.id}#{extra_params}" }.
        to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "when attempting to view organization analytics and being a member of the organization" do
    before do
      get "/api/analytics/#{endpoint}?api_token=#{org_member_token.secret}&organization_id=#{pro_org_member.organization_id}#{extra_params}"
    end

    it "renders JSON as the content type" do
      expect(response.content_type).to eq "application/json"
    end
  end

  context "when attempting to view another organization analytics and not belonging to that organization" do
    it "raises the ActiveRecord::RecordNotFound error" do
      org = create(:organization)
      expect { get "/api/analytics/#{endpoint}?api_token=#{org_member_token.secret}&organization_id=#{org.id}#{extra_params}" }.
        to raise_error ActiveRecord::RecordNotFound
    end
  end
end
