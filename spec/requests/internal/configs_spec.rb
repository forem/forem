require "rails_helper"

RSpec.describe "/internal/config", type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:user, :super_admin) }

  describe "POST internal/events as a user" do
    before do
      sign_in(user)
    end

    it "bars the regular user to access" do
      expect { post "/internal/config", params: {} }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "POST internal/events" do
    before do
      sign_in(admin)
    end

    it "updates main_social_image" do
      SiteConfig.main_social_image = "https://dummyimage.com/100x100"
      expected_image_url = "https://dummyimage.com/300x300"
      post "/internal/config", params: { site_config: { main_social_image: expected_image_url } }
      expect(SiteConfig.main_social_image).to eq(expected_image_url)
    end
  end
end
