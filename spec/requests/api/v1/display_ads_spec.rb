require "rails_helper"

# rubocop:disable RSpec/InstanceVariable

RSpec.describe "Api::V1::DisplayAds" do
  let!(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }

  before do
    allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true)
    @ad1 = create(:display_ad, published: true, approved: true)
  end

  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
    before { user.add_role(:admin) }
  end

  context "when authenticated and authorized and get to index" do
    include_context "when user is authorized"

    describe "GET /api/display_ads" do
      it "returns json response" do
        get api_display_ads_path, headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.size).to eq(1)
      end
    end

    describe "GET /api/display_ads/:id" do
      it "returns json response" do
        get api_display_ad_path(@ad1.id), headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body).to include(
          "id" => @ad1.id,
          "published" => true,
          "approved" => true,
          "cached_tag_list" => "",
          "clicks_count" => 0,
        )
      end
    end
  end

  context "when unauthenticated and get to index" do
    it "returns unauthorized" do
      get api_display_ads_path, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthorized and get to show" do
    it "returns unauthorized" do
      get api_display_ads_path, params: { id: @ad1.id },
                                headers: v1_headers.merge({ "api-key" => "invalid api key" })
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
