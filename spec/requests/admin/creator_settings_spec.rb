require "rails_helper"

RSpec.describe "/creator_settings/new" do
  let!(:current_user) { create(:user, :creator) }
  let!(:non_admin_user) { create(:user) }
  let(:params) do
    { creator_settings_form:
      {
        checked_code_of_conduct: true,
        checked_terms_and_conditions: true,
        community_name: "Climbing Life",
        invite_only_mode: false,
        primary_brand_color_hex: "#000000",
        public: true
      } }
  end

  before do
    allow(Settings::General).to receive(:waiting_on_first_user).and_return(false)
  end

  describe "GET /admin/creator_settings/new" do
    before do
      sign_in current_user
      get new_admin_creator_setting_path
    end

    context "when the user is a creator" do
      it "allows the request" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the correct page" do
        expect(response.body).to include("Lovely! Let's set up your Forem.")
      end
    end

    context "when the user is a not a creator" do
      before do
        sign_in non_admin_user
      end

      it "blocks the request" do
        expect do
          get new_admin_creator_setting_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/creator_settings/new" do
      before do
        sign_in current_user
        get new_admin_creator_setting_path
      end

      it "allows a creator to successfully fill out the creator setup form", :aggregate_failures do
        post admin_creator_settings_path, params: params

        expect(current_user.saw_onboarding).to be(true)
        expect(current_user.checked_code_of_conduct).to be(true)
        expect(current_user.checked_terms_and_conditions).to be(true)
        expect(response).to redirect_to(:root).and have_http_status(:found)
      end

      it "updates settings admin action taken" do
        expect do
          post admin_creator_settings_path, params: params
        end.to change(Settings::General, :admin_action_taken_at)
      end
    end
  end
end
