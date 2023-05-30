require "rails_helper"

RSpec.describe "Onboardings" do
  let(:user) do
    create(:user,
           saw_onboarding: false,
           _skip_creating_profile: true,
           profile: create(:profile, location: "Llama Town"))
  end

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

  describe "GET /onboarding/tags" do
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

  describe "PATCH /onboarding" do
    context "when signed in" do
      before { sign_in user }

      it "updates the user's last_onboarding_page attribute" do
        params = { user: { last_onboarding_page: "v2: personal info form", username: "test" } }
        expect do
          patch "/onboarding", params: params
        end.to change(user, :last_onboarding_page)
      end

      it "updates the user's username attribute" do
        params = { user: { username: "WilhuffTarkin" } }
        expect do
          patch "/onboarding", params: params
        end.to change(user, :username).to("wilhufftarkin")
      end

      it "returns a 422 error if the username is blank" do
        params = { user: { username: "" } }
        patch "/onboarding", params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "updates the user's profile" do
        params = { profile: { location: "Galactic Empire" } }
        expect do
          patch "/onboarding", params: params
        end.to change(user.profile, :location).to("Galactic Empire")
      end

      it "does not update the user's last_onboarding_page if it is empty" do
        params = { user: { last_onboarding_page: "" } }
        expect do
          patch "/onboarding", params: params
        end.not_to change(user, :last_onboarding_page)
      end
    end

    context "when signed out" do
      it "returns a not found error if user is not signed in" do
        patch "/onboarding.json", params: {}
        expect(response.parsed_body["error"]).to include("Please sign in")
      end
    end
  end

  describe "PATCH /onboarding/checkbox" do
    context "when signed in" do
      before { sign_in user }

      it "updates saw_onboarding boolean" do
        patch "/onboarding/checkbox.json", params: {}
        expect(user.saw_onboarding).to be(true)
      end

      it "updates checked_code_of_conduct and checked_terms_and_conditions" do
        patch "/onboarding/checkbox.json",
              params: {
                checked_code_of_conduct: "1",
                checked_terms_and_conditions: "1"
              }

        expect(user.checked_code_of_conduct).to be(true)
        expect(user.checked_terms_and_conditions).to be(true)
      end
    end

    context "when signed out" do
      it "returns a not found error if user is not signed in" do
        patch "/onboarding/checkbox.json", params: {}
        expect(response.parsed_body["error"]).to include("Please sign in")
      end
    end
  end

  describe "PATCH /onboarding/notifications" do
    before { sign_in user }

    it "updates onboarding checkbox" do
      user.update_column(:saw_onboarding, false)

      expect do
        patch notifications_onboarding_path(format: :json),
              params: { notifications: { tab: "notifications", email_newsletter: 1 } }
      end.to change { user.notification_setting.reload.email_newsletter }.from(false).to(true)
      expect(user.saw_onboarding).to be(true)
    end

    it "can toggle email_newsletter" do
      expect do
        patch notifications_onboarding_path(format: :json),
              params: { notifications: { tab: "notifications", email_newsletter: 1 } }
      end.to change { user.notification_setting.reload.email_newsletter }.from(false).to(true)

      expect do
        patch notifications_onboarding_path(format: :json),
              params: { notifications: { tab: "notifications", email_newsletter: 0 } }
      end.to change { user.notification_setting.reload.email_newsletter }.from(true).to(false)
    end

    it "can toggle email_digest_periodic" do
      expect do
        patch notifications_onboarding_path(format: :json),
              params: { notifications: { tab: "notifications", email_digest_periodic: 1 } }
      end.to change { user.notification_setting.reload.email_digest_periodic }.from(false).to(true)

      expect do
        patch notifications_onboarding_path(format: :json),
              params: { notifications: { tab: "notifications", email_digest_periodic: 0 } }
      end.to change { user.notification_setting.reload.email_digest_periodic }.from(true).to(false)
    end
  end
end
