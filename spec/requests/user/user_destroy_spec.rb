require "rails_helper"

RSpec.describe "UserDestroy" do
  let(:user) { create(:user, :without_profile, profile_image: nil) }

  describe "GET /settings/account" do
    it "offers to delete account when user has an email" do
      sign_in user
      get "/settings/account"
      expect(response.body).to include("Delete Account").and include("Deleting your account will")
    end

    it "offers to set an email when user doesn't have an email" do
      shallow_user = create(:user, :without_profile, email: nil, profile_image: nil)
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

      it "schedules a user delete job, signs out, and redirects to sign up", :aggregate_failures do
        sidekiq_assert_enqueued_with(job: Users::DeleteWorker) do
          delete "/users/full_delete"
        end
        expect(controller.current_user).to be_nil
        expect(response).to redirect_to new_user_registration_path
        expect(flash[:global_notice]).to include("Your account deletion is scheduled")
      end
    end

    context "when user doesn't have an email" do
      let!(:shallow_user) { create(:user, :without_profile, email: nil, profile_image: nil) }

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
    let(:mailer_class) { NotifyMailer }
    let(:mailer) { double }
    let(:message_delivery) { double }

    context "when user has an email" do
      before do
        sign_in user
      end

      it "sends an email, updates the destroy_token in cache, and sets flash notice", :aggregate_failures do
        allow(Rails.cache).to receive(:write).and_call_original
        allow(mailer_class).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:account_deletion_requested_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now)

        post user_request_destroy_path

        expect(mailer_class).to have_received(:with).with(user: user, token: instance_of(String))
        expect(mailer).to have_received(:account_deletion_requested_email)
        expect(message_delivery).to have_received(:deliver_now)
        expect(Rails.cache).to have_received(:write).with("user-destroy-token-#{user.id}", any_args)
        expect(flash[:settings_notice]).to include("You have requested account deletion")
      end
    end

    context "when user doesn't have an email" do
      let!(:shallow_user) { create(:user, :without_profile, email: nil, profile_image: nil) }

      before do
        sign_in shallow_user
      end

      it "redirects to account page" do
        post user_request_destroy_path

        expect(response).to redirect_to("/settings/account")
        expect(flash[:settings_notice]).to include("provide an email")
      end
    end

    it "does not send an email if already requested" do
      allow(Rails.cache).to receive(:exist?).with("user-destroy-token-#{user.id}", local_cache: false).and_return(true)
      allow(mailer_class).to receive(:with).and_return(mailer)
      allow(mailer).to receive(:account_deletion_requested_email).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_now)

      sign_in user
      post user_request_destroy_path

      expect(mailer).not_to have_received(:account_deletion_requested_email)
      expect(flash[:settings_notice]).to include("You have already requested")
    end
  end

  describe "GET /users/confirm_destroy" do
    let(:token) { SecureRandom.hex(10) }

    context "with user signed in" do
      before do
        sign_in user
      end

      it "displays a flash message if user doesn't have a destroy_token" do
        get user_confirm_destroy_path(token: token)
        expect(flash[:settings_notice]).to include("Your token has expired,")
      end

      it "renders not_found and records Honeycomb fields if destroy_token != token" do
        mismatch_token = SecureRandom.hex(8)
        allow(Honeycomb).to receive(:add_field)
        allow(Rails.cache).to receive(:read).and_call_original
        allow(Rails.cache).to receive(:read).with("user-destroy-token-#{user.id}",
                                                  local_cache: false).and_return(mismatch_token)
        expect do
          get user_confirm_destroy_path(token: token)
        end.to raise_error(ActionController::RoutingError)
        expect(Honeycomb).to have_received(:add_field).with("destroy_token", mismatch_token)
        expect(Honeycomb).to have_received(:add_field).with("token", token)
      end

      it "renders template with verification fields if destroy_token is correct", :aggregate_failures do
        allow(Rails.cache).to receive(:read).and_call_original
        allow(Rails.cache).to receive(:read).with("user-destroy-token-#{user.id}", local_cache: false).and_return(token)
        get user_confirm_destroy_path(token: token)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="delete__account__username__field"')
        expect(response.body).to include('id="delete__account__verification__field"')
        expect(response.body).to include('id="delete__account__btn"')
      end
    end

    context "without a user" do
      it "displays a flash message" do
        get user_confirm_destroy_path(token: token)
        expect(flash[:alert]).to include("You must be logged in")
      end
    end
  end
end
