require "rails_helper"

RSpec.describe "Api::V0::Instances", type: :request do
  describe "GET /api/instance" do
    it "returns the correct attributes", :aggregate_failures do
      create(:user)
      get api_instance_path

      expect(response.parsed_body["cover_image_url"]).to eq Settings::General.main_social_image
      expect(response.parsed_body["description"]).to eq Settings::Community.community_description
      expect(response.parsed_body["logo_image_url"]).to eq Settings::General.logo_png
      expect(response.parsed_body["name"]).to eq Settings::Community.community_name
      expect(response.parsed_body["registered_users_count"]).to eq User.registered.estimated_count
      expect(response.parsed_body["tagline"]).to eq Settings::Community.tagline
      expect(response.parsed_body["version"]).to match(/(stable|beta|edge)\.\d{8}\.\d+/)
      expect(response.parsed_body["visibility"]).to eq "public"
    end

    context "when the Forem is public" do
      it "returns public for visibility" do
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(false)
        allow(Settings::UserExperience).to receive(:public).and_return(true)
        get api_instance_path

        expect(response.parsed_body["visibility"]).to eq "public"
      end
    end

    context "when the Forem is not public" do
      it "returns private for visibility" do
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(false)
        allow(Settings::UserExperience).to receive(:public).and_return(false)
        get api_instance_path

        expect(response.parsed_body["visibility"]).to eq "private"
      end
    end

    context "when the Forem is pending" do
      it "returns pending for visibility" do
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(true)
        get api_instance_path

        expect(response.parsed_body["visibility"]).to eq "pending"
      end
    end
  end
end
