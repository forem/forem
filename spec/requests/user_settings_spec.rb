require "rails_helper"

RSpec.describe "UserSettings", type: :request do
  let(:user) { create(:user) }

  describe "GET /settings/:tab" do
    context "when not signed-in" do
      it "returns not_foudn" do
        get "/settings"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when signed-in" do
      before do
        login_as user
      end

      it "renders various settings tabs properly" do
        %w[organization switch-organizations billing misc].each do |tab|
          get "/settings/#{tab}"
          expect(response.body).to include("Settings for")
        end
      end

      it "doesn't let user access membership if user has no monthly_dues" do
        get "/settings/membership"
        expect(response.body).not_to include("Settings for")
      end

      it "allows user with monthly_dues to access membership" do
        user.update_column(:monthly_dues, 5)
        get "/settings/membership"
        expect(response.body).to include("Settings for")
      end

      it "renders heads up dupe account message with proper param" do
        get "/settings?state=previous-registration"
        expect(response.body).to include("There is an existing account authorized with that social account")
      end
    end
  end

  describe "PUT /update/:id" do
    before do
      login_as user
    end

    it "updates summary" do
      put "/users/#{user.id}", params: { user: { tab: "profile", summary: "Hello new summary" } }
      expect(user.summary).to eq("Hello new summary")
    end

    it "updates username to too short username" do
      put "/users/#{user.id}", params: { user: { tab: "profile", username: "h" } }
      expect(response.body).to include("Username is too short")
    end
  end
end
