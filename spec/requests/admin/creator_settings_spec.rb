require "rails_helper"

RSpec.describe "/creator_settings/new", type: :request do
  let!(:creator) { create(:user, :creator) }
  let!(:non_admin_user) { create(:user) }
  let(:params) do
    { community_name: "Climbing Life",
      logo_svg: "https://dummyimage.com/300x300.png",
      primary_brand_color_hex: "000000",
      public: true,
      invite_only: false }
  end

  before do
    allow(FeatureFlag).to receive(:enabled?).with(:creator_onboarding).and_return(true)
    allow(Settings::General).to receive(:waiting_on_first_user).and_return(false)
  end

  describe "GET /admin/creator_settings/new" do
    before do
      sign_in creator
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
        sign_in creator
        get new_admin_creator_setting_path
      end

      it "allows a creator to successfully fill out the creator setup form", :aggregate_failures do
        post admin_creator_settings_path, params: params
        expect(creator.saw_onboarding).to eq(true)
        expect(creator.checked_code_of_conduct).to eq(true)
        expect(creator.checked_terms_and_conditions).to eq(true)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
