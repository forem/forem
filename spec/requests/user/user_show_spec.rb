require "rails_helper"

RSpec.describe "UserShow", type: :request do
  let_it_be(:user) { create(:user) }

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

    it "renders the proper additional username for a user when one is present" do
      user.update(github_username: "username")
      expect(response.body).to include CGI.escapeHTML(user.github_username)
    end

    xit "renders the proper email for a user when one is public and present" do
      user.update(email_public: true, email: "user@dev.to")
      #   user.reload
      expect(response.body).to include CGI.escapeHTML(user.email)
    end
  end
end
