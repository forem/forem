require "rails_helper"

RSpec.describe "Api::V0::ForemDirectories", type: :request do
  describe "GET /api/forem_directories" do
    it "returns the correct attributes" do
      Timecop.freeze(Time.current) do
        get api_forem_directories_path

        expect(response.parsed_body["cover_image_url"]).to eq Settings::General.main_social_image
        expect(response.parsed_body["description"]).to eq Settings::Community.community_description
        expect(response.parsed_body["logo_image_url"]).to eq Settings::General.logo_png
        expect(response.parsed_body["name"]).to eq Settings::Community.community_name
        expect(response.parsed_body["tagline"]).to eq Settings::Community.tagline
        expect(response.parsed_body["version"]).to eq "edge.#{Time.current.strftime('%Y%m%d')}.0"
        expect(response.parsed_body["visibility"]).to eq "public"
      end
    end
  end
end
