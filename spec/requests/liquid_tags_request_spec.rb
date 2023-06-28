require "rails_helper"

RSpec.describe "LiquidTags" do
  describe "GET /liquid_tags" do
    context "when not signed in do" do
      it "returns a list of all custom Liquid tags" do
        get liquid_tags_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "returns an array of all custom Liquid tags", :aggregate_failures do
        get liquid_tags_path

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["liquid_tags"]).to be_an_instance_of(Array)
        expect(json["liquid_tags"]).not_to be_empty
      end
    end
  end
end
