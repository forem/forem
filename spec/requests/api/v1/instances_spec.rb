require "rails_helper"

RSpec.describe "Api::V1::Instances" do
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

  describe "GET /api/instance" do
    it "returns the correct attributes", :aggregate_failures do
      create(:user)
      get api_instance_path, headers: headers

      expect(response.parsed_body["context"]).to eq ApplicationConfig["FOREM_CONTEXT"]
      expect(response.parsed_body["cover_image_url"]).to eq Settings::General.main_social_image
      expect(response.parsed_body["description"]).to eq Settings::Community.community_description
      expect(response.parsed_body["display_in_directory"]).to eq Settings::UserExperience.display_in_directory
      expect(response.parsed_body["domain"]).to eq Settings::General.app_domain
      expect(response.parsed_body["logo_image_url"]).to eq Settings::General.logo_png
      expect(response.parsed_body["name"]).to eq Settings::Community.community_name
      expect(response.parsed_body["tagline"]).to eq Settings::Community.tagline
      expect(response.parsed_body["version"]).to match(/(stable|beta|edge)\.\d{8}\.\d+/)
      expect(response.parsed_body["visibility"]).to eq "public"
    end

    context "when the Forem is public" do
      it "returns public for visibility" do
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(false)
        allow(Settings::UserExperience).to receive(:public).and_return(true)
        get api_instance_path, headers: headers

        expect(response.parsed_body["visibility"]).to eq "public"
      end

      it "sets Fastly Surrogate-Control headers" do
        expected_surrogate_control_headers = %w[max-age=600 stale-if-error=26400]
        get api_instance_path, headers: headers

        expect(response.headers["Surrogate-Control"]).to eq(expected_surrogate_control_headers.join(", "))
      end
    end

    context "when the Forem is not public" do
      it "returns private for visibility" do
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(false)
        allow(Settings::UserExperience).to receive(:public).and_return(false)
        get api_instance_path, headers: headers

        expect(response.parsed_body["visibility"]).to eq "private"
      end
    end

    context "when the Forem is pending" do
      it "returns pending for visibility" do
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(true)
        get api_instance_path, headers: headers

        expect(response.parsed_body["visibility"]).to eq "pending"
      end
    end
  end
end
