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
      it "creates a new user and sends a magic link" do
        # stub find_by to force the "create new user" branch
        allow(User).to receive(:find_by).with(email: "new@example.com").and_return(nil)
        # stub Devise token to a known value
        allow(Devise).to receive(:friendly_token).with(20).and_return("dummy_password")
        # stub Faker for a deterministic username/name
        allow(Faker::Movie).to receive(:quote).and_return("Test Quote")

        expect {
          expect_any_instance_of(User).to receive(:send_magic_link!).once
          post "/magic_links", params: { email: "new@example.com" }
        }.to change(User, :count).by(1)

        new_user = User.order(:created_at).last
        expect(new_user.email).to eq("new@example.com")
        expect(new_user.username).to eq("testquote")
        expect(new_user.name).to eq("Test Quote")
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
        user.update!(sign_in_token: "valid_token", sign_in_token_sent_at: Time.current)

        get "/magic_links/valid_token"

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the token matches a user but is expired" do
      it "redirects to new_user_session_path with alert" do
        user.update!(sign_in_token: "expired_token", sign_in_token_sent_at: 21.minutes.ago)

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
