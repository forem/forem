require "rails_helper"

RSpec.describe "Onboardings" do
  let(:user) { create(:user, saw_onboarding: false) }

  describe "GET /onboarding" do
    it "redirects user if unauthenticated" do
      get onboarding_url
      expect(response).to redirect_to("/enter")
    end

    it "return 200 when authenticated" do
      sign_in user
      get onboarding_url
      expect(response).to have_http_status(:ok)
    end

    it "contains proper data attribute keys" do
      sign_in user
      get onboarding_url
      expect(response.body).to include("data-community-description")
      expect(response.body).to include("data-community-logo")
      expect(response.body).to include("data-community-background")
      expect(response.body).to include("data-community-name")
    end

    it "contains proper data attribute values if the onboarding config is present" do
      allow(Settings::General).to receive(:onboarding_background_image).and_return("onboarding_background_image.png")

      sign_in user
      get onboarding_url

      expect(response.body).to include(Settings::Community.community_description)
      expect(response.body).to include(Settings::General.onboarding_background_image)
    end
  end

  describe "GET /tags/onboarding" do
    let(:headers) do
      {
        Accept: "application/json",
        "Content-Type": "application/json"
      }
    end

    before do
      sign_in user
      allow(Settings::General).to receive(:suggested_tags).and_return(%w[beginners javascript career])
    end

    it "returns tags" do
      create(:tag, name: Settings::General.suggested_tags.first)

      get tags_onboarding_path, headers: headers

      expect(response.parsed_body.size).to eq(1)
    end

    it "returns tags with the correct json representation" do
      tag = create(:tag, name: Settings::General.suggested_tags.first)

      get tags_onboarding_path, headers: headers

      response_tag = response.parsed_body.first
      expect(response_tag.keys).to \
        match_array(OnboardingsController::TAG_ONBOARDING_ATTRIBUTES.map(&:to_s))
      expect(response_tag["id"]).to eq(tag.id)
      expect(response_tag["name"]).to eq(tag.name)
      expect(response_tag["taggings_count"]).to eq(tag.taggings_count)
    end

    it "returns suggested and supported tags" do
      not_suggested_but_supported = create(:tag, name: "notsuggestedbutsupported", supported: true, suggested: false)
      neither_suggested_nor_supported = create(:tag, name: "definitelynotasuggestedtag", supported: false)

      get tags_onboarding_path, headers: headers

      expect(response.parsed_body.filter { |t| t["name"] == not_suggested_but_supported.name }).not_to be_empty
      expect(response.parsed_body.filter { |t| t["name"] == neither_suggested_nor_supported.name }).to be_empty
    end

    it "sets the correct edge caching surrogate key for all tags" do
      tag = create(:tag, name: Settings::General.suggested_tags.first)

      get tags_onboarding_path, headers: headers

      expected_key = ["tags", tag.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end
end
