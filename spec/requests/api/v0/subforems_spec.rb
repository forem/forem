require "rails_helper"

RSpec.describe "Api::V0::Subforems" do
  describe "GET /api/subforems" do
    let!(:discoverable_subforem) { create(:subforem, discoverable: true, domain: "#{rand(1000)}.com") }
    let!(:non_discoverable_subforem) { create(:subforem, discoverable: false, domain: "#{rand(1000)}.com") }

    it "returns a list of discoverable subforems with correct attributes", :aggregate_failures do
      get api_subforems_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to be_an(Array)
      expect(response.parsed_body.size).to eq(1) # Only the discoverable one

      subforem_data = response.parsed_body.first

      expect(subforem_data["domain"]).to eq(discoverable_subforem.domain)
      expect(subforem_data["root"]).to eq(discoverable_subforem.root)
      expect(subforem_data["name"]).to eq(Settings::Community.community_name(subforem_id: discoverable_subforem.id))
      expect(subforem_data["description"]).to eq(Settings::Community.community_description(subforem_id: discoverable_subforem.id))
      expect(subforem_data["logo_image_url"]).to eq(Settings::General.logo_png(subforem_id: discoverable_subforem.id))
      expect(subforem_data["cover_image_url"]).to eq(Settings::General.main_social_image)
    end

    it "sets Surrogate-Key header" do
        get api_subforems_path
        expected_surrogate_key = discoverable_subforem.record_key
        expect(response.headers["Surrogate-Key"]).to include(expected_surrogate_key)
    end

    it "sets Cache-Control headers" do
        get api_subforems_path
        expect(response.headers["Cache-Control"]).to be_present
    end
  end
end