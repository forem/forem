# spec/requests/magic_links_spec.rb
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

    context "when the email matches an existing user" do
      before do
        allow(User).to receive(:find_by).with(email: user.email).and_return(user)
        allow(user).to receive(:send_magic_link!)
      end

      it "renders the create template and sends a magic link without altering confirmation" do
        original_confirmed_at = user.confirmed_at

        post "/magic_links", params: { email: user.email }

        expect(response.body).to include("Check your email")
        expect(user).to have_received(:send_magic_link!).once
        # confirmed_at should remain exactly what it was
        expect(user.reload.confirmed_at).to be_within(1.second).of(original_confirmed_at)
      end
    end

    context "when the email does not match any user" do
      let(:email) { "new@example.com" }
    
      before do
        allow(User).to receive(:find_by).with(email: email).and_return(nil)
        allow(Devise).to receive(:friendly_token).with(20).and_return("dummy_password")
        allow(Images::ProfileImageGenerator).to receive(:call).and_return("avatar_url")
    
        # <-- this is the *spy*, installed *before* the controller runs
        expect_any_instance_of(User).to receive(:send_magic_link!).once
      end
    
      it "creates a new user, skips confirmation and sends the magic link" do
        freeze_time do
          expect { post "/magic_links", params: { email: email } }
            .to change(User, :count).by(1)
    
          new_user = User.order(:created_at).last
    
          expect(new_user.email).to          eq(email)
          expect(new_user.username).to       include("member_")
          expect(new_user.name).to           include("member_")
          expect(new_user.registered_at).to  eq(Time.current)
          expect(new_user.confirmed_at).to   be_nil
          expect(response.body).to include("Check your email")
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
