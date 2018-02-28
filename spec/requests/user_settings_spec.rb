require "rails_helper"

RSpec.describe "UserSettings", type: :request do
  before do
    @user = create(:user)
    login_as @user
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
