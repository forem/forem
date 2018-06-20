# http://localhost:3000/api/comments?a_id=23
require "rails_helper"

RSpec.describe "Videos", type: :request do
  before do
    @user = create(:user)
    login_as @user
  end

  describe "GET /videos/new" do
    it "redirects if non permission" do
      get "/videos/new"
      expect(response.body).to include("You are being")
    end

    it "renders video page if has permission" do
      @user.add_role(:video_permission)
      get "/videos/new"
      expect(response.body).to include("Upload Video File")
    end
  end
end
