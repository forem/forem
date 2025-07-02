# spec/requests/sessions_spec.rb
require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  describe "POST /users/sign_in" do
    it "signs the user in and updates tracked fields" do
      expect(user.current_sign_in_at).to be_nil
      expect(user.current_sign_in_ip).to be_nil

      post user_session_path, params: {
        user: {
          email: user.email,
          password: user.password
        }
      }

      # Devise normally redirects to a default or configured path on success.
      expect(response).to have_http_status(:found)

      # Reload from DB to observe changes from user.update_tracked_fields!(request).
      user.reload
      expect(user.current_sign_in_at).not_to be_nil
      expect(user.current_sign_in_ip).not_to be_nil
    end

    it "fails to sign in with invalid credentials" do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "wrong-password"
        }
      }

      # Typically Devise re-renders the sign-in form with status 200 on failure.
      expect(response).to have_http_status(:ok)

      # Ensure the DB was not updated since sign-in failed.
      user.reload
      expect(user.current_sign_in_at).to be_nil
      expect(user.current_sign_in_ip).to be_nil
    end

    it "redirects to root path if stored location is /signout_confirm" do
      allow_any_instance_of(ApplicationController).to receive(:stored_location_for).and_return("/signout_confirm")

      post user_session_path, params: {
        user: {
          email: user.email,
          password: user.password
        }
      }

      # Devise normally redirects to a default or configured path on success.
      expect(response).to have_http_status(:found)
      # Check that the user is redirected to the root path.
      expect(response).to redirect_to(root_path(signin: 'true'))
      # Reload from DB to observe changes from user.update_tracked_fields!(request).
      user.reload
      expect(user.current_sign_in_at).not_to be_nil
      expect(user.current_sign_in_ip).not_to be_nil
    end
  end

  describe "DELETE /users/sign_out" do
    context "when user is signed in" do
      before do
        sign_in user
        # Confirm the user has some tracked fields from sign-in.
        user.update_columns(current_sign_in_at: Time.zone.now, current_sign_in_ip: "127.0.0.1")
        # set cookies["forem_user_signed_in"] to simulate a signed-in user
        cookies["forem_user_signed_in"] = "true"
      end

      it "signs the user out, clears tracked fields, and deletes the forem_user_signed_in cookie" do
        # Sanity-check before sign-out.
        expect(user.current_sign_in_at).not_to be_nil
        expect(user.current_sign_in_ip).not_to be_nil
        p cookies["forem_user_signed_in"]
        expect(cookies["forem_user_signed_in"]).to be_present

        delete destroy_user_session_path

        expect(response).to have_http_status(:found)
        user.reload
        expect(user.current_sign_in_at).to be_nil
        expect(user.current_sign_in_ip).to be_nil
        # Check that the cookie is deleted.
        expect(cookies["forem_user_signed_in"]).to be_blank
      end
    end

    context "when user is not signed in" do
      it "does not raise an error and simply redirects" do
        expect do
          delete destroy_user_session_path
        end.not_to raise_error

        expect(response).to have_http_status(:found)
      end
    end
  end
end
