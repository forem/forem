require "rails_helper"

# vcr_option = {
#   cassette_name: "getstream-index",
#   allow_playback_repeats: "true",
# }

RSpec.describe "NotificationsIndex", type: :request do
  let(:user) { create(:user) }

  describe "GET logged-in notifications index" do
    before do
      sign_in user
    end
    it "renders page with proper sidebar" do
      get "/notifications"
      expect(response.body).to include("Notifications")
    end
  end
end
