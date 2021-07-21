require "rails_helper"

RSpec.describe "ProfilePreviewCards", type: :request do
  let(:user) { create(:profile).user }

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

  describe "GET /:id as JSON" do
    let(:profile) { user.profile }

    context "when signed out" do
      it "does not find an unknown user id" do
        expect { get profile_preview_card_path(9999), as: :json }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "is a successful response" do
        get profile_preview_card_path(user), as: :json

        expect(response).to have_http_status(:ok)
      end

      it "returns the data", :aggregate_failures do
        get profile_preview_card_path(user), as: :json

        preview_card = response.parsed_body
        expect(preview_card["summary"]).to eq(profile.summary)
        expect(preview_card["employment_title"]).to eq(profile.employment_title)
        expect(preview_card["employer_name"]).to eq(profile.employer_name)
        expect(preview_card["employer_url"]).to eq(profile.employer_url)
        expect(preview_card["location"]).to eq(profile.location)
        expect(preview_card["education"]).to eq(profile.education)
        expect(preview_card["created_at"]).to eq(profile.created_at.utc.iso8601)
      end

      it "has the correct card color" do
        user.setting.update(brand_color1: Faker::Color.hex_color)

        get profile_preview_card_path(user), as: :json

        expected_card_color = Color::CompareHex.new([user_colors(user)[:bg], user_colors(user)[:text]]).brightness(0.88)
        expect(response.parsed_body["card_color"]).to eq(expected_card_color)
      end

      it "does not return the email if the user has asked not to" do
        user.setting.update_columns(display_email_on_profile: false)

        get profile_preview_card_path(user), as: :json

        preview_card = response.parsed_body
        expect(preview_card.key?("email")).to be(false)
      end

      it "returns the email if the user wants to" do
        user.setting.update_columns(display_email_on_profile: true)

        get profile_preview_card_path(user), as: :json

        preview_card = response.parsed_body
        expect(preview_card["email"]).to eq(user.email)
      end
    end

    context "when signed in" do
      before { sign_in(user) }

      it "does not find an unknown user id" do
        expect { get profile_preview_card_path(9999), as: :json }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "is a successful response" do
        get profile_preview_card_path(user), as: :json

        expect(response).to have_http_status(:ok)
      end

      it "returns the data", :aggregate_failures do
        get profile_preview_card_path(user), as: :json

        preview_card = response.parsed_body
        expect(preview_card["summary"]).to eq(profile.summary)
        expect(preview_card["employment_title"]).to eq(profile.employment_title)
        expect(preview_card["employer_name"]).to eq(profile.employer_name)
        expect(preview_card["employer_url"]).to eq(profile.employer_url)
        expect(preview_card["location"]).to eq(profile.location)
        expect(preview_card["education"]).to eq(profile.education)
        expect(preview_card["created_at"]).to eq(profile.created_at.utc.iso8601)
      end

      it "has the correct card color" do
        user.setting.update(brand_color1: Faker::Color.hex_color)

        get profile_preview_card_path(user), as: :json

        expected_card_color = Color::CompareHex.new([user_colors(user)[:bg], user_colors(user)[:text]]).brightness(0.88)
        expect(response.parsed_body["card_color"]).to eq(expected_card_color)
      end

      it "does not return the email if the user has asked not to" do
        user.setting.update_columns(display_email_on_profile: false)

        get profile_preview_card_path(user), as: :json

        preview_card = response.parsed_body
        expect(preview_card.key?("email")).to be(false)
      end

      it "returns the email if the user wants to" do
        user.setting.update_columns(display_email_on_profile: true)

        get profile_preview_card_path(user), as: :json

        preview_card = response.parsed_body
        expect(preview_card["email"]).to eq(user.email)
      end
    end
  end
end
