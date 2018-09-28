require "rails_helper"

vcr_option = {
  cassette_name: "google_api_request_spec"
}

RSpec.describe "Analytics", type: :request, vcr: vcr_option do
  describe "GET /analytics" do
    context "when signed in as an authorized user" do
      let(:user)                { create(:user, :analytics) }
      let(:article1)            { create(:article, user_id: user.id) }
      let(:article2)            { create(:article, user_id: user.id) }
      let(:ga_double)           { instance_double(GoogleAnalytics) }

      before do
        allow(GoogleAnalytics).to receive(:new).and_return(ga_double)
        allow(ga_double).to receive(:create_service_account_credential).and_return({})
        allow(ga_double).to receive(:get_pageviews) do
          { article1.id.to_s => "0", article2.id.to_s => "0" }
        end
        login_as user
      end

      it "raise ParameterMissing if no proper params is given" do
        expect { get "/analytics" }.to raise_error ActionController::ParameterMissing
      end

      it "returns pageviews" do
        get "/analytics?article_ids=#{article1.id},#{article2.id}"
        expect(JSON.parse(response.body)).to eq(article1.id.to_s => "0", article2.id.to_s => "0")
      end

      it "returns pageviews for super_admins" do
        user.remove_role :analytics_beta_tester
        user.add_role :super_admin
        get "/analytics?article_ids=#{article1.id},#{article2.id}"
        expect(JSON.parse(response.body)).to eq(article1.id.to_s => "0", article2.id.to_s => "0")
      end

      it "updates article view counts" do
        Reaction.create!(
          user_id: user.id,
          reactable_id: article1.id,
          reactable_type: "Article",
          category: "readinglist",
        )
        expect(article1.reload.previous_positive_reactions_count).not_to eq(article1.positive_reactions_count)
        get "/analytics?article_ids=#{article1.id},#{article2.id}"
        expect(article1.reload.previous_positive_reactions_count).to eq(article1.positive_reactions_count)
      end
    end
  end
end
