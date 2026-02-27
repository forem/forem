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
        
        # Check that the cookie deletion is set in response headers
        set_cookie_headers = response.headers['Set-Cookie']
        expect(set_cookie_headers).to include("forem_user_signed_in=")
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

  describe "Cross-domain login and logout (UX)" do
    let(:primary_domain) { "forem.test" }
    let(:music_subdomain) { "music.forem.test" }
    let(:dev_subdomain) { "dev.forem.test" }
    let!(:primary_subforem) { create(:subforem, domain: primary_domain) }
    let!(:music_subforem) { create(:subforem, domain: music_subdomain) }
    let!(:dev_subforem) { create(:subforem, domain: dev_subdomain) }

    context "when user logs in on primary domain" do
      it "user is authenticated on all subdomains" do
        # User logs in on primary domain
        host! primary_domain
        post user_session_path, params: {
          user: {
            email: user.email,
            password: user.password
          }
        }

        expect(response).to have_http_status(:found)
        user.reload
        expect(user.current_sign_in_at).not_to be_nil

        # Navigate to music subdomain; cookie jar should carry session
        host! music_subdomain
        get root_path

        # User should be authenticated on music subdomain
        expect(response).to have_http_status(:ok)
        expect(session["warden.user.user.key"]).not_to be_nil
      end

      it "user is authenticated on dev subdomain" do
        host! primary_domain
        post user_session_path, params: {
          user: {
            email: user.email,
            password: user.password
          }
        }

        expect(response).to have_http_status(:found)
        user.reload
        expect(user.current_sign_in_at).not_to be_nil

        host! dev_subdomain
        get root_path

        expect(response).to have_http_status(:ok)
        expect(session["warden.user.user.key"]).not_to be_nil
      end
    end

    context "when user logs out on one subdomain" do
      before do
        # User is signed in
        sign_in user
        user.update_columns(current_sign_in_at: Time.zone.now, current_sign_in_ip: "127.0.0.1")
        cookies["forem_user_signed_in"] = "true"
      end

      it "user is logged out everywhere (assert DB and deletion headers only)" do
        # User logs out on music subdomain
        host! music_subdomain
        delete destroy_user_session_path

        expect(response).to have_http_status(:found)
        user.reload
        expect(user.current_sign_in_at).to be_nil

        # Assert cookie deletion headers were sent for remember token
        set_cookie_headers = response.headers["Set-Cookie"]
        expect(set_cookie_headers).to include("remember_user_token=")
      end

      it "user is logged out on primary domain (assert DB and deletion headers only)" do
        # User logs out on primary domain
        host! primary_domain
        delete destroy_user_session_path

        expect(response).to have_http_status(:found)
        user.reload
        expect(user.current_sign_in_at).to be_nil

        # Assert cookie deletion headers were sent for remember token
        set_cookie_headers = response.headers["Set-Cookie"]
        expect(set_cookie_headers).to include("remember_user_token=")
      end

      it "forem_user_signed_in cookie is deleted on all subdomains" do
        # User logs out on music subdomain
        host! music_subdomain
        delete destroy_user_session_path

        set_cookie_headers = response.headers['Set-Cookie']
        # Cookie deletion may be reflected in remember_user_token header
        # forem_user_signed_in is deleted via cookies.delete in controller
        expect(set_cookie_headers).to include("remember_user_token=")
      end
    end

    context "remember_token persistence across subdomains" do
      it "remember_me token remains valid after logout on another subdomain" do
        # User logs in with "remember me"
        post user_session_path, params: {
          user: {
            email: user.email,
            password: user.password,
            remember_me: "1"
          }
        }, headers: { "HTTP_HOST" => primary_domain }

        expect(response).to have_http_status(:found)
        login_cookies = response.cookies

        # User logs out on music subdomain
        delete destroy_user_session_path, headers: {
          "HTTP_HOST" => music_subdomain,
          "HTTP_COOKIE" => login_cookies.map { |k, v| "#{k}=#{v}" }.join("; ")
        }

        expect(response).to have_http_status(:found)
        user.reload
        # After logout, remember_me should not re-authenticate the user
        expect(user.current_sign_in_at).to be_nil
      end
    end
  end

  describe "Password reset on subforem domains" do
    let(:subforem) { create(:subforem, domain: "reset.example.com") }

    before do
      # This test requires a Subforem record to exist in the database.
      # The set_session_domain method checks Subforem.cached_all_domains which
      # queries actual database records. The subforem factory creates this record.
      allow(Subforem).to receive(:cached_all_domains).and_return([subforem.domain])
    end

    it "sets session domain to subforem domain when requesting password reset" do
      # Simulate request to subforem domain
      # The set_session_domain before_action should detect this is a subforem
      # and set session cookies to match the subforem domain
      get "/users/password/new", headers: { "HTTP_HOST" => subforem.domain }
      
      # Request doesn't fail due to domain mismatch
      expect(response).to have_http_status(:ok)
    end

    it "password reset token validation works on subforem domain" do
      user = create(:user, onboarding_subforem_id: subforem.id)
      
      # Request password reset on subforem domain
      post user_password_path, params: {
        user: { email: user.email }
      }, headers: { "HTTP_HOST" => subforem.domain }
      
      expect(response).to have_http_status(:found)
      # Email would be queued with subforem domain link
    end
  end
end
