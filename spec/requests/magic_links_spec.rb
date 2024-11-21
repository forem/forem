require "rails_helper"

RSpec.describe "MagicLinks", type: :request do
  describe "POST /magic_links" do
    let(:user) { create(:user, email: "test@example.com") }

    context "when the email matches an existing user" do
      it "renders the create template and sends a magic link" do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:send_magic_link)

        post "/magic_links", params: { email: user.email }

        expect(response.body).to include("Check your email")
        expect(user).to have_received(:send_magic_link).once
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
end
