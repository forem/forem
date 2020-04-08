require "rails_helper"

RSpec.describe "UserShow", type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:org, reload: true) { create(:organization) }

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

    it "renders the proper organization that a user belongs to" do
      user.update(organization: org)
      expect(response.body).to include CGI.escapeHTML(user.organizations)
    end
  end
end
