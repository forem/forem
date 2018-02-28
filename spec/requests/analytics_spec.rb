require "rails_helper"

vcr_option = {
  cassette_name: "google_api_request_spec",
}

RSpec.describe "Analytics", type: :request, vcr: vcr_option do
  describe "GET /analytics" do
    it "returns json" do
      get "/analytics?article_ids=0,1,2,3"
      expect(response.content_type).to eq("application/json")
    end

    it "returns 200" do
      get "/analytics?article_ids=0,1,2,3"
      expect(response).to have_http_status(200)
    end

    it "raise ParameterMissing if no proper params is given" do
      expect { get "/analytics" }.to raise_error ActionController::ParameterMissing
    end

    it "returns empty json when user is not signed in" do
      get "/analytics?article_ids=0,1,2,3"
      expect(response.body).to eq("{}")
    end

    context "when signed in" do
      let(:user) { create(:user) }
      let(:article1) { create(:article, user_id: user.id) }
      let(:article2) { create(:article, user_id: user.id) }

      before do
        login_as user
      end

      it "returns empty json if current user has no priviledge" do
        get "/analytics?article_ids=0,1,2,3"
        expect(response.body).to eq("{}")
      end

      it "returns pageviews if user is an admin" do
        user.add_role(:admin)
        get "/analytics?article_ids=#{article1.id},#{article2.id}"
        expect(JSON.parse(response.body)).to eq(article1.id.to_s => "0", article2.id.to_s => "0")
      end

      it "returns pageviews if user is has beta access" do
        user.add_role(:analytics_beta_tester)
        get "/analytics?article_ids=#{article1.id},#{article2.id}"
        expect(JSON.parse(response.body)).to eq(article1.id.to_s => "0", article2.id.to_s => "0")
      end
    end
  end
end
