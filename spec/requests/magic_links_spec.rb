require "rails_helper"

RSpec.describe "MagicLinks", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  describe "GET /magic_links/new" do
    it "renders the new template" do
      get "/magic_links/new"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sign in or create your account wth a")
    end

    it "renders code page if params state is code" do
      get "/magic_links/new?state=code"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Enter the code you received in your email!")
    end
  end

  describe "POST /magic_links" do
    let(:user) { create(:user, email: "test@example.com", confirmed_at: 1.day.ago) }
    let(:email) { "new@example.com" }
    let!(:subforem) { create(:subforem, domain: "example.com") }

    before do
      allow(Devise).to receive(:friendly_token).with(20).and_return("dummy_password")
      allow(Images::ProfileImageGenerator).to receive(:call).and_return("avatar_url")
    end

    context "when the email matches an existing user" do
      before do
        allow(User).to receive(:find_by).with(email: user.email).and_return(user)
        allow(user).to receive(:send_magic_link!)
        allow(Settings::Authentication).to receive(:acceptable_domain?).and_call_original
      end

      it "renders the create template and sends a magic link without altering confirmation" do
        original_confirmed_at = user.confirmed_at

        post "/magic_links", params: { email: user.email }

        expect(response.body).to include("Check your email")
        expect(user).to have_received(:send_magic_link!).once
        expect(user.reload.confirmed_at).to be_within(1.second).of(original_confirmed_at)
      end
    end

    context "when the email does not match any user" do
      before do
        allow(User).to receive(:find_by).with(email: email).and_return(nil)
      end

      it "returns an error if the instance is invite-only" do
        allow(ForemInstance).to receive(:invitation_only?).and_return(true)

        post "/magic_links", params: { email: email }

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq("Forem is invite-only.")
      end

      it "creates a new user, skips confirmation and sends the magic link" do
        freeze_time do
          allow(ForemInstance).to receive(:invitation_only?).and_return(false)
          allow(Settings::Authentication).to receive(:acceptable_domain?).with(domain: "example.com").and_return(true)

          expect {
            post "/magic_links", params: { email: email }, headers: { "Host" => subforem.domain }
          }.to change(User, :count).by(1)

          new_user = User.order(:created_at).last

          expect(new_user.email).to          eq(email)
          expect(new_user.username).to       include("member_")
          expect(new_user.name).to           include("member_")
          expect(new_user.registered_at).to  eq(Time.current)
          expect(new_user.confirmed_at).to   be_nil
          expect(response.body).to include("Check your email")
          expect(new_user.sign_in_token).not_to be_nil
        end
      end

      it "assigns onboarding_subforem_id based on the referer header" do
        freeze_time do
          allow(ForemInstance).to receive(:invitation_only?).and_return(false)
          allow(Settings::Authentication).to receive(:acceptable_domain?).with(domain: "example.com").and_return(true)

          expect {
            post "/magic_links", params: { email: email }, headers: { "Host" => subforem.domain }
          }.to change(User, :count).by(1)

          new_user = User.order(:created_at).last
          expect(new_user.onboarding_subforem_id).to eq(subforem.id)
        end
      end

      context "when the email domain is not acceptable" do
        before do
          allow(ForemInstance).to receive(:invitation_only?).and_return(false)
          allow(Settings::Authentication).to receive(:acceptable_domain?).with(domain: "example.com").and_return(false)
        end

        it "does not create a user and redirects with domain error" do
          expect {
            post "/magic_links", params: { email: email }
          }.not_to change(User, :count)

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context "when no email is provided" do
      it "raises ActiveRecord::RecordNotFound" do
        expect { post "/magic_links", params: {} }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /magic_links/:id" do
    let(:token) { "valid_token" }

    context "when the token matches a user and is not expired" do
      it "confirms the user and redirects to root_path" do
        freeze_time do
          user = create(
            :user,
            sign_in_token:          token,
            sign_in_token_sent_at:  10.minutes.ago,
            confirmed_at:           nil
          )

          get "/magic_links/#{token}"

          expect(response).to redirect_to(root_path)
          expect(user.reload.confirmed_at).to be_within(1.second).of(Time.current)
        end
      end

      it "does **not** update confirmed_at if it was already present" do
        freeze_time do
          confirmed_time = 1.day.ago
          user = create(
            :user,
            sign_in_token:          token,
            sign_in_token_sent_at:  10.minutes.ago,
            confirmed_at:           confirmed_time
          )

          get "/magic_links/#{token}"

          expect(response).to redirect_to(root_path)
          expect(user.reload.confirmed_at).to be_within(1.second).of(confirmed_time)
        end
      end
    end
  end
end
