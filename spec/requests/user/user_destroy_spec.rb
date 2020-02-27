require "rails_helper"

RSpec.describe "UserDestroy", type: :request do
  let(:user) { create(:user) }

  describe "GET /settings/account" do
    it "offers to delete account when user has an email" do
      sign_in user
      get "/settings/account"
      expect(response.body).to include("DELETE ACCOUNT").and include("Deleting your account will")
    end

    it "offers to set an email when user doesn't have an email" do
      shallow_user = create(:user, email: nil)
      sign_in shallow_user
      get "/settings/account"
      expect(response.body).not_to include("Deleting your account will")
      expect(response.body).to include("provide an email")
    end
  end

  describe "DELETE /users/full_delete" do
    context "when user has an email" do
      before do
        sign_in user
      end

      it "schedules a user delete job" do
        sidekiq_assert_enqueued_with(job: Users::DeleteWorker) do
          delete "/users/full_delete"
        end
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

    context "when user doesn't have an email" do
      let!(:shallow_user) { create(:user, email: nil) }

      before do
        sign_in shallow_user
      end

      it "redirects to account page" do
        delete "/users/full_delete"
        expect(response).to redirect_to("/settings/account")
        expect(flash[:settings_notice]).to include("provide an email")
      end
    end
  end

  describe "POST /users/request_destroy" do
    context "when user has an email" do
      before do
        allow(Rails.cache).to receive(:write).and_call_original
        allow(NotifyMailer).to receive(:account_deletion_requested_email).and_call_original
        sign_in user
        post "/users/request_destroy"
      end

      it "sends an email" do
        expect(NotifyMailer).to have_received(:account_deletion_requested_email).with(user, instance_of(String))
      end

      it "updates the destroy_token" do
        user.reload
        expect(Rails.cache).to have_received(:write).with("user-destroy-token-#{user.id}", any_args)
      end

      it "sets flash notice" do
        expect(flash[:settings_notice]).to include("You have requested account deletion")
      end
    end

    context "when user doesn't have an email" do
      let!(:shallow_user) { create(:user, email: nil) }

      before do
        sign_in shallow_user
      end

      it "redirects to account page" do
        post "/users/request_destroy"
        expect(response).to redirect_to("/settings/account")
        expect(flash[:settings_notice]).to include("provide an email")
      end
    end
  end

  describe "GET /users/confirm_destroy" do
    let(:token) { SecureRandom.hex(10) }

    context "with user signed in" do
      before do
        sign_in user
      end

      it "renders not_found if user doesn't have a destroy_token" do
        expect do
          get user_confirm_destroy_path(token: token)
        end.to raise_error(ActionController::RoutingError)
      end

      it "renders not_found if destroy_token != token" do
        allow(Rails.cache).to receive(:read).and_return(SecureRandom.hex(8))
        expect do
          get user_confirm_destroy_path(token: token)
        end.to raise_error(ActionController::RoutingError)
      end

      it "renders template if destroy_token is correct" do
        allow(Rails.cache).to receive(:read).and_return(token)
        get user_confirm_destroy_path(token: token)
        expect(response).to have_http_status(:ok)
      end
    end

    context "without a user" do
      it "renders not_found" do
        expect do
          get user_confirm_destroy_path(token: token)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
