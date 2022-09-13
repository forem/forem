require "rails_helper"

RSpec.describe "Badges", type: :request do
  let(:user) { create(:user) }

  describe "GET /badges" do
    let!(:badges) { create_list(:badge, 3) }

    context "when logged in" do
      before { sign_in user }

      it "shows all the badges" do
        get "/badges"
        expect(response.body).to include "Badges"
        badges.each do |badge|
          expect(response.body).to include CGI.escapeHTML(badge.badge_image_url)
        end
      end
    end

    context "when logged out" do
      it "shows all the badges" do
        get "/badges"
        expect(response.body).to include "Badges"
        badges.each do |badge|
          expect(response.body).to include CGI.escapeHTML(badge.badge_image_url)
        end
      end
    end
  end

  describe "GET /badge/:slug" do
    let(:badge) { create(:badge) }

    context "when badge exists" do
      it "shows the badge" do
        get "/badge/#{badge.slug}"
        expect(response.body).to include CGI.escapeHTML(badge.title)
      end
    end

    context "when badge does not exist" do
      it "renders 404" do
        expect { get "/badge/that-does-not-exists" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
