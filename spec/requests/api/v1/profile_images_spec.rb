require "rails_helper"

RSpec.describe "Api::V1::ProfileImages", type: :request do
  let(:headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }

  describe "GET /api/profile_images/:username" do
    it "returns 404 if the username is not taken" do
      get api_profile_image_path("invalid-username"), headers: headers

      expect(response).to have_http_status(:not_found)
    end

    context "when the username relates to an user" do
      let(:user) { create(:user) }

      it "returns the user profile image information" do
        get api_profile_image_path(user.username), headers: headers

        expect(response.parsed_body).to eq(
          "type_of" => "profile_image",
          "image_of" => "user",
          "profile_image" => user.profile_image_url_for(length: 640),
          "profile_image_90" => user.profile_image_url_for(length: 90),
        )
      end
    end

    context "when the username relates to an invited user" do
      let(:user) { create(:user, :invited) }

      it "returns a 404" do
        get api_profile_image_path(user.username), headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the username relates to an organization" do
      let(:organization) { create(:organization) }

      it "returns the organization's profile image information" do
        get api_profile_image_path(organization.username), headers: headers

        expect(response.parsed_body).to eq(
          "type_of" => "profile_image",
          "image_of" => "organization",
          "profile_image" => organization.profile_image_url_for(length: 640),
          "profile_image_90" => organization.profile_image_url_for(length: 90),
        )
      end
    end
  end
end
