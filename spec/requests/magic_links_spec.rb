require "rails_helper"

RSpec.describe "MagicLinks", type: :request do
  describe "POST /magic_links" do
    let(:user) { create(:user, email: "test@example.com") }

    context "when the email matches an existing user" do
      it "renders the create template and sends a magic link" do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:send_magic_link!)

        post "/magic_links", params: { email: user.email }

        expect(response.body).to include("Check your email")
        expect(user).to have_received(:send_magic_link!).once
      end
    end

    context "when the email does not match any user" do
      it "renders the create template without sending a magic link" do
        allow(User).to receive(:find_by).and_return(nil)

        post "/magic_links", params: { email: "nonexistent@example.com" }

        expect(response.body).to include("Check your email")
      end
    end

    context "when no email is provided" do
      it "returns a not_found response" do
        expect { post "/magic_links", params: {} }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /magic_links/:id" do
    let(:user) { create(:user) }

    context "when the token matches a user and is not expired" do
      it "signs in the user and redirects to root_path with notice" do
        user.update(sign_in_token: "valid_token", sign_in_token_sent_at: Time.current)

        get "/magic_links/valid_token"

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the token matches a user but is expired" do
      it "redirects to new_user_session_path with alert" do
        user.update(sign_in_token: "expired_token", sign_in_token_sent_at: 21.minutes.ago)

        get "/magic_links/expired_token"

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(response.body).to include("Invalid or expired link")
      end
    end

    context "when the token does not match any user" do
      it "redirects to new_user_session_path with alert" do
        get "/magic_links/invalid_token"

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(response.body).to include("Invalid or expired link")
      end
    end
  end
end
