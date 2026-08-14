require "rails_helper"

RSpec.describe "Dev Tools", type: :request do
  describe "GET /dev_tools" do
    context "when operating strictly under production contexts or standard test scopes" do
      it "returns a 403 Forbidden preventing exposure" do
        get "/dev_tools"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when operating in development contexts" do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
        create(:user) # ensure at least one user
      end

      it "successfully renders the dev tool dashboard" do
        get "/dev_tools"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Development Utilities")
      end
    end
  end

  describe "POST /dev_tools/sign_in_as" do
    let(:target_user) { create(:user) }

    context "when operating strictly under production contexts or standard test scopes" do
      it "returns a 403 Forbidden preventing unauthorized assumption" do
        post "/dev_tools/sign_in_as", params: { user_id: target_user.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when operating in development contexts" do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "successfully bypasses Devise and assumes identity then redirects back to root" do
        # We ensure it explicitly hits the devise bypass redirect.
        post "/dev_tools/sign_in_as", params: { user_id: target_user.id }
        
        expect(response).to redirect_to("/")
        expect(flash[:notice]).to include("Successfully assumed identity of #{target_user.username}")
        # Further confirm sign-in
        get "/" # trigger request to lock in warden
        expect(controller.current_user).to eq(target_user)
      end
    end
  end
end
