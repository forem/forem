require "rails_helper"

RSpec.describe "User changes password" do
  let(:password) { "password123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }

  describe "POST /users/update_password" do
    it "does not update the password if the current password is wrong" do
      sign_in user
      post user_update_password_path,
           params: {
             current_password: "wrongwrong",
             password: "testtest",
             password_confirmation: "testtest"
           }

      expect(response.body).to include("Current password is invalid")
    end

    it "does not update the password if the new password is too short" do
      sign_in user
      post user_update_password_path,
           params: {
             current_password: password,
             password: "test",
             password_confirmation: "test"
           }

      expect(response.body).to include("Password is too short (minimum is 8 characters)")
    end

    it "does not update the password if the new passwords don't match" do
      sign_in user
      post user_update_password_path,
           params: {
             current_password: password,
             password: "testtest",
             password_confirmation: "testtesy"
           }

      expect(response.body).to include("error")
      expected_message = CGI.escapeHTML("Password doesn't match password confirmation")
      expect(response.body).to include(expected_message)
    end

    it "updates the password, keeps the user signed in, and displays a notice on /settings/account" do
      sign_in user
      post user_update_password_path,
           params: {
             current_password: password,
             password: "testtest",
             password_confirmation: "testtest"
           }

      expect(response.body).not_to include("error")
      expect(response).to redirect_to("/settings/account")

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(request.fullpath).to eq("/settings/account")
      expect(response.body).to include(I18n.t("devise.passwords.updated_not_active"))
    end
  end
end
