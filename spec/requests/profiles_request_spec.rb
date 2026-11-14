require "rails_helper"

RSpec.describe "Profiles" do
  let(:profile) { create(:profile) }

  describe "POST /profiles" do
    context "when signed out" do
      it "redirects to the login page" do
        patch profile_path(profile), params: {}
        expect(response).to redirect_to(new_magic_link_path)
      end
    end

    context "when signed in" do
      before { sign_in(profile.user) }

      it "updates the user" do
        new_name = "New name, who dis?"
        expect do
          patch profile_path(profile), params: { user: { name: new_name } }
        end.to change { profile.user.reload.name }.to(new_name)
      end

      it "updates the profile" do
        new_location = "New location, who dis?"
        expect do
          patch profile_path(profile), params: { profile: { location: new_location } }
        end.to change { profile.reload.location }.to(new_location)
      end

      it "removes the profile image" do
        expect(profile.user.profile_image_url).to be_present

        patch profile_path(profile), params: { user: { remove_profile_image: "1" } }

        expect(profile.user.reload.profile_image_url).to be_blank
      end

      it "keeps the profile image when removal is not requested" do
        expect do
          patch profile_path(profile), params: { user: { remove_profile_image: "0" } }
        end.not_to change { profile.user.reload.profile_image_url }
      end

      it "uploads a profile banner image" do
        banner_image = fixture_file_upload("800x600.png", "image/png")

        expect do
          patch profile_path(profile), params: { user: { profile_banner_image: banner_image } }
        end.to change { profile.user.reload.profile_banner_image_url.present? }.from(false).to(true)
        expect(response).to redirect_to(user_settings_path)
      end

      it "removes the profile banner image" do
        profile.user.update!(profile_banner_image: fixture_file_upload("800x600.png", "image/png"))
        expect(profile.user.reload.profile_banner_image_url).to be_present

        patch profile_path(profile), params: { user: { remove_profile_banner_image: "1" } }

        expect(profile.user.reload.profile_banner_image_url).to be_blank
      end

      it "keeps the profile banner image when removal is not requested" do
        profile.user.update!(profile_banner_image: fixture_file_upload("800x600.png", "image/png"))

        expect do
          patch profile_path(profile), params: { user: { remove_profile_banner_image: "0" } }
        end.not_to change { profile.user.reload.profile_banner_image_url }
      end

      it "rejects a banner image that is not an image file" do
        patch profile_path(profile), params: { user: { profile_banner_image: "A String" } }

        expect(profile.user.reload.profile_banner_image_url).to be_blank
        expect(response.body).to include("invalid file type")
      end
    end
  end
end
