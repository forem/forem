require "rails_helper"

RSpec.describe "Videos", type: :request do
  let(:unauthorized_user) { create(:user) }
  let(:authorized_user)   { create(:user, :video_permission) }

  describe "GET /videos/new" do
    context "when not authorized" do
      it "redirects non-logged in users" do
        get "/videos/new"
        is_expected.to redirect_to("/enter")
      end

      it "redirects logged in users" do
        login_as unauthorized_user
        get "/videos/new"
        is_expected.to redirect_to("/enter")
      end
    end

    context "when authorized" do
      it "allows authorized users" do
        login_as authorized_user
        get "/videos/new"
        expect(response.body).to include "Upload Video File"
      end
    end
  end

  describe "POST /videos" do
    context "when not authorized" do
      it "redirects non-logged in users" do
        post "/videos"
        is_expected.to redirect_to("/enter")
      end

      it "redirects logged in users" do
        login_as unauthorized_user
        post "/videos"
        is_expected.to redirect_to("/enter")
      end
    end

    context "when authorized" do
      before do
        login_as authorized_user
      end

      valid_params = {
        article: {
          video: "something.mp4"
        }
      }

      xit "creates an article for the logged in user" do
        post "/videos", params: valid_params
      end
    end
  end
end
