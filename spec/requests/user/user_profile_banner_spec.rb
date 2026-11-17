require "rails_helper"

RSpec.describe "User profile banner image" do
  let(:user) { create(:user) }

  describe "GET /:username" do
    it "uses the brand color banner when no banner image is set" do
      get "/#{user.username}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="brand-bg"')
      expect(response.body).not_to include("brand-bg__image")
    end

    it "shows the banner image when one is set" do
      user.update!(profile_banner_image: fixture_file_upload("800x600.png", "image/png"))

      get "/#{user.username}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("brand-bg--image")
      expect(response.body).to include("brand-bg__image")
      expect(response.body).to include(File.basename(user.reload.profile_banner_image_url))
    end

    it "goes back to the brand color banner once the image is removed" do
      user.update!(profile_banner_image: fixture_file_upload("800x600.png", "image/png"))
      user.update!(remove_profile_banner_image: true)

      get "/#{user.username}"

      expect(response.body).not_to include("brand-bg__image")
    end
  end

  describe "GET /settings" do
    before { sign_in user }

    it "shows the banner image upload field" do
      get user_settings_path

      expect(response.body).to include('name="user[profile_banner_image]"')
      expect(response.body).not_to include('name="user[remove_profile_banner_image]"')
    end

    it "shows the preview and the remove option when a banner image is set" do
      user.update!(profile_banner_image: fixture_file_upload("800x600.png", "image/png"))

      get user_settings_path

      expect(response.body).to include("user-profile-banner-preview")
      expect(response.body).to include('name="user[remove_profile_banner_image]"')
    end
  end
end
