require "rails_helper"

RSpec.describe "MenusShow" do
  context "when signed out" do
    it "renders the signin page" do
      get "/menu"
      expect(response).to redirect_to("/magic_links/new")
    end
  end

  context "when signed in" do
    let(:user) { create(:user) }
    before do
      sign_in user
    end

    it "renders the menu page" do
      get "/menu"

      expect(response.body).to include("My Profile")
      expect(response.body).to include("/#{user.username}")
    end
  end
end