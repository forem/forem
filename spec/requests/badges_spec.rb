require "rails_helper"

RSpec.describe "Badges", type: :request do
  let(:user)   { create(:user) }
  let(:badge) { create(:badge) }

  describe "GET /badge/:slug" do
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
