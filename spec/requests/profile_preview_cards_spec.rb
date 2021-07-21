require "rails_helper"

RSpec.describe "ProfilePreviewCards", type: :request do
  let(:user) { create(:user) }

  describe "GET /:id" do
    context "when signed out" do
      it "does not find an unknown user id" do
        expect { get profile_preview_card_path(9999) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "is a successful response" do
        get profile_preview_card_path(user)

        expect(response).to have_http_status(:ok)
      end

      it "returns the data" do
        get profile_preview_card_path(user)

        expect(response.body).to include("profile-preview-card__content")
      end
    end

    context "when signed in" do
      before { sign_in(user) }

      it "does not find an unknown user id" do
        expect { get profile_preview_card_path(9999) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "is a successful response" do
        get profile_preview_card_path(user)

        expect(response).to have_http_status(:ok)
      end

      it "returns the data" do
        get profile_preview_card_path(user)

        expect(response.body).to include("profile-preview-card__content")
      end
    end
  end
end
