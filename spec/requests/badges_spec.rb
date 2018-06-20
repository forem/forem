require "rails_helper"

RSpec.describe "Badges", type: :request do
  let(:user)   { create(:user) }
  let(:badge) { create(:badge) }

  describe "GET /badge/:slug" do
    it "shows the badge" do
      get "/badge/#{badge.slug}"
      expect(response.body).to include badge.title
    end
  end
end
