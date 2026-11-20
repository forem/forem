require "rails_helper"

RSpec.describe "EmailAuthorizations" do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /verify_email_ownership" do
    it "verifies the email authorization when confirmation_token matches" do
      email_authorization = create(:email_authorization, user: user)

      get verify_email_authorizations_path(
        username: user.username,
        confirmation_token: email_authorization.confirmation_token,
      )

      expect(response).to redirect_to(root_path)
      expect(email_authorization.reload.verified_at).to be_present
    end

    it "raises RoutingError when confirmation_token is mismatched" do
      email_authorization = create(:email_authorization, user: user)

      expect do
        get verify_email_authorizations_path(username: user.username, confirmation_token: "wrong-token")
      end.to raise_error(ActionController::RoutingError)
      expect(email_authorization.reload.verified_at).to be_nil
    end

    it "raises RoutingError when stored confirmation_token is blank and param is omitted" do
      email_authorization = create(:email_authorization, user: user)
      email_authorization.update_column(:confirmation_token, nil)

      expect do
        get verify_email_authorizations_path(username: user.username)
      end.to raise_error(ActionController::RoutingError)
      expect(email_authorization.reload.verified_at).to be_nil
    end

    it "raises RoutingError when the user has no email_authorizations" do
      expect do
        get verify_email_authorizations_path(username: user.username, confirmation_token: "any-token")
      end.to raise_error(ActionController::RoutingError)
    end
  end
end
