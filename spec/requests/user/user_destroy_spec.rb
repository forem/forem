require "rails_helper"

RSpec.describe "UserDestroy", type: :request do
  let(:user) { create(:user) }

  describe "DELETE /users/full_delete" do
    before do
      sign_in user
    end

    it "schedules a user delete job" do
      expect do
        delete "/users/full_delete"
      end.to have_enqueued_job(Users::SelfDeleteJob).with(user.id)
    end

    it "signs out" do
      delete "/users/full_delete"
      expect(controller.current_user).to eq nil
    end

    it "redirects to root" do
      delete "/users/full_delete"
      expect(response).to redirect_to "/"
      expect(flash[:global_notice]).to include("Your account deletion is scheduled")
    end
  end

  describe "GET /users/request_destroy" do
    before do
      allow(NotifyMailer).to receive(:account_deletion_requested_email).and_call_original
      sign_in user
      get "/users/request_destroy"
    end

    it "sends an email" do
      expect(NotifyMailer).to have_received(:account_deletion_requested_email).with(user)
    end

    it "updates the destroy_token" do
      user.reload
      expect(user.destroy_token).to be_truthy
    end

    it "sets flash notice" do
      expect(flash[:settings_notice]).to include("You have requested account deletion")
    end
  end

  describe "GET /users/confirm_destroy" do
    let(:token) { SecureRandom.hex(10) }

    before do
      sign_in user
    end

    it "renders not_found if user doesn't have a destroy_token" do
      expect do
        get user_confirm_destroy_path(token: token)
      end.to raise_error(ActionController::RoutingError)
    end

    it "renders not_found if destroy_token != token" do
      user.update_column(:destroy_token, SecureRandom.hex(8))
      expect do
        get user_confirm_destroy_path(token: token)
      end.to raise_error(ActionController::RoutingError)
    end

    it "renders template if destroy_token is correct" do
      user.update_column(:destroy_token, token)
      get user_confirm_destroy_path(token: token)
      expect(response).to have_http_status(:ok)
    end
  end
end
