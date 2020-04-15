require "rails_helper"

RSpec.describe "UserShow", type: :request do
  let_it_be(:user) { create(:user, email_public: true, currently_hacking_on: "JSON-LD", education: "DEV University") }

  describe "GET /:slug (user)" do
    before do
      user.update_columns(employment_title: "SEO", employer_name: "DEV", linkedin_url: "www.linkedin.com/company/example/")
      get user.path
    end

    it "returns a 200 status when navigating to the user's page" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the proper username for a user" do
      expect(response.body).to include CGI.escapeHTML(user.username)
    end

    it "renders the proper bio for a user" do
      expect(response.body).to include CGI.escapeHTML(user.summary)
    end

    it "renders the proper education for a user" do
      expect(response.body).to include CGI.escapeHTML(user.education)
    end

    it "renders the proper currently hacking on info for a user" do
      expect(response.body).to include CGI.escapeHTML(user.currently_hacking_on)
    end

    it "renders the proper job title for a user" do
      expect(response.body).to include CGI.escapeHTML(user.employment_title)
    end

    it "renders the proper employer name for a user" do
      expect(response.body).to include CGI.escapeHTML(user.employer_name)
    end

    it "renders the proper linkedin url for a user" do
      expect(response.body).to include CGI.escapeHTML(user.linkedin_url)
    end

    it "renders the proper additional username for a user when one is present" do
      expect(response.body).to include CGI.escapeHTML(user.github_username)
    end

    it "renders the proper email for a user when one is public and present" do
      expect(response.body).to include CGI.escapeHTML(user.email)
    end
  end

  context "when user signed in" do
    before do
      sign_in user
      get user.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end

  context "when user not signed in" do
    before do
      get user.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).to include "application/ld+json"
      end
    end
  end

  context "when user not signed in but internal nav triggered" do
    before do
      get user.path + "?i=i"
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end
end
