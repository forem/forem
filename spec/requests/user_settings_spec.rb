require "rails_helper"

RSpec.describe "UserSettings", type: :request do
  before do
    @user = create(:user)
    login_as @user
  end

  describe "GET /settings" do
    it "renders various settings tabs properly" do
      get "/settings/organization"
      expect(response.body).to include("Settings for")
      get "/settings/switch-organizations"
      expect(response.body).to include("Settings for")
      # get "/settings/integrations"
      # expect(response.body).to include("Settings for")
      get "/settings/billing"
      expect(response.body).to include("Settings for")
      get "/settings/misc"
      expect(response.body).to include("Settings for")
      get "/settings/membership"
      expect(response.body).not_to include("Settings for")
      @user.update_column(:monthly_dues, 5)
      get "/settings/membership"
      expect(response.body).to include("Settings for")
    end
  end

  describe "PUT /update/:id" do
    it "updates summary" do
      put "/users/#{@user.id}", params: { user: {tab: "profile", summary: "Hello new summary"} }
      expect(@user.summary).to eq("Hello new summary")
    end

    it "updates username to too short username" do
      put "/users/#{@user.id}", params: { user: {tab: "profile", username: "h"} }
      expect(response.body).to include("Username is too short")
    end
  end
end
