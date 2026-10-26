require "rails_helper"

RSpec.describe "Password reset flow" do
  let(:user) { create(:user) }

  describe "GET /users/password" do
    it "redirects to /users/password/new instead of returning 404" do
      get "/users/password"

      expect(response).to redirect_to("/users/password/new")
    end
  end

  describe "GET /settings/password" do
    it "redirects to /settings/account instead of returning 404" do
      sign_in user
      get "/settings/password"

      expect(response).to redirect_to("/settings/account")
    end
  end

  describe "POST /users/password" do
    context "when accessed without a HTTP_REFERER header" do
      it "redirects unauthenticated users to /enter instead of /users/password (404)" do
        get new_user_password_path
        post user_password_path, params: { user: { email: user.email } }

        expect(response).to redirect_to(sign_up_path)
        expect(flash[:global_notice]).to eq(I18n.t("devise.passwords.reset_instructions_sent"))

        follow_redirect!
        expect(response).to have_http_status(:ok)
      end

      it "redirects signed-in users to /settings/account instead of /users/password (404)" do
        sign_in user
        get new_user_password_path
        post user_password_path, params: { user: { email: user.email } }

        expect(response).to redirect_to(user_settings_path(:account))
        expect(flash[:global_notice]).to eq(I18n.t("devise.passwords.reset_instructions_sent"))

        follow_redirect!
        expect(response).to have_http_status(:ok)
      end
    end

    context "when accessed with a valid same-host HTTP_REFERER" do
      it "redirects back to the referrer path" do
        sign_in user
        get new_user_password_path, headers: { "HTTP_REFERER" => "http://www.example.com/settings/account" }
        post user_password_path, params: { user: { email: user.email } }

        expect(response).to redirect_to("/settings/account")
      end

      it "preserves the original referrer if /users/password/new is reloaded" do
        sign_in user
        get new_user_password_path, headers: { "HTTP_REFERER" => "http://www.example.com/settings/account" }
        get new_user_password_path, headers: { "HTTP_REFERER" => "http://www.example.com/users/password/new" }
        post user_password_path, params: { user: { email: user.email } }

        expect(response).to redirect_to("/settings/account")
      end
    end

    context "when accessed with an external HTTP_REFERER" do
      it "ignores the external referrer and redirects safely" do
        get new_user_password_path, headers: { "HTTP_REFERER" => "https://www.google.com/" }
        post user_password_path, params: { user: { email: user.email } }

        expect(response).to redirect_to(sign_up_path)
      end
    end
  end

  describe "GET /users/password/edit" do
    context "without a reset_password_token" do
      it "redirects unauthenticated users to the sign in page with an alert" do
        get edit_user_password_path

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq(I18n.t("devise.passwords.no_token"))
      end

      it "redirects signed-in users to /settings/account with an error notice" do
        sign_in user
        get edit_user_password_path

        expect(response).to redirect_to(user_settings_path(:account))
        expect(flash[:error]).to eq(I18n.t("devise.passwords.no_token"))
      end
    end

    context "with a reset_password_token" do
      it "renders the password reset form for signed-in users" do
        sign_in user
        raw_token = user.send_reset_password_instructions

        get edit_user_password_path(reset_password_token: raw_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Change your password")
      end
    end
  end

  describe "PUT /users/password" do
    let(:new_password) { "NewSecurePass123!" }

    context "when an unauthenticated user resets their password" do
      it "signs the user in and redirects to /settings/account with a notice" do
        # Simulate visiting /enter -> /users/password/new -> POST /users/password -> /enter
        get sign_up_path
        get new_user_password_path, headers: { "HTTP_REFERER" => "http://www.example.com/enter" }
        post user_password_path,
             params: { user: { email: user.email } },
             headers: { "HTTP_REFERER" => "http://www.example.com/users/password/new" }
        follow_redirect!(headers: { "HTTP_REFERER" => "http://www.example.com/users/password/new" })

        raw_token = user.send_reset_password_instructions

        put user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: new_password,
            password_confirmation: new_password
          }
        }

        expect(response).to redirect_to(user_settings_path(:account))
        expect(flash[:settings_notice]).to eq(I18n.t("devise.passwords.updated"))

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("devise.passwords.updated"))
        expect(user.reload.valid_password?(new_password)).to be(true)
      end
    end

    context "when an already signed-in user resets their password" do
      it "keeps the user signed in with the new password and redirects to /settings/account with a notice" do
        sign_in user
        raw_token = user.send_reset_password_instructions

        put user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: new_password,
            password_confirmation: new_password
          }
        }

        expect(response).to redirect_to(user_settings_path(:account))
        expect(flash[:settings_notice]).to eq(I18n.t("devise.passwords.updated"))

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(request.fullpath).to eq("/settings/account")
        expect(response.body).to include(I18n.t("devise.passwords.updated"))
        expect(user.reload.valid_password?(new_password)).to be(true)
      end
    end

    context "when an unconfirmed user resets their password via email token" do
      let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      it "confirms the user, signs them in, and redirects to /settings/account" do
        raw_token = unconfirmed_user.send_reset_password_instructions

        put user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: new_password,
            password_confirmation: new_password
          }
        }

        expect(response).to redirect_to(user_settings_path(:account))
        expect(unconfirmed_user.reload.confirmed_at).to be_present

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(request.fullpath).to eq("/settings/account")
      end
    end

    context "when password confirmation does not match" do
      it "renders the edit form with an error message once" do
        raw_token = user.send_reset_password_instructions

        put user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: new_password,
            password_confirmation: "mismatch123"
          }
        }

        expect(response.body).to include(CGI.escapeHTML("Password doesn't match password confirmation"))
        expect(response.body.scan('id="error_explanation"').size).to eq(1)
      end
    end
  end
end
