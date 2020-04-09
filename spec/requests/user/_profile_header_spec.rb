require "rails_helper"

RSpec.describe "UserShow", type: :request do
  let_it_be(:user, reload: true) { create(:user, profile_image: Faker::Avatar.image) }

  describe "GET /:slug (user)" do
    before do
      get user.path
    end

    it "returns a 200 status when navigating to the user's page" do
      expect(response).to have_http_status(:success)
    end

    it "renders the proper username for a user" do
      expect(response.body).to include CGI.escapeHTML(user.username)
    end

    it "renders the proper bio for a user" do
      expect(response.body).to include CGI.escapeHTML(user.summary)
    end

    it "renders the proper profile image for a user" do
      expect(response.body).to include CGI.escapeHTML(user.profile_image.to_s)
    end
  end
end
