require "rails_helper"

RSpec.describe SocialImageHelper, type: :helper do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  describe "#profile_social_image_url" do
    context "when user has a social image set in profile data" do
      before do
        user.profile.update_column(:data, user.profile.data.merge("social_image" => "https://example.com/user_profile.png"))
      end

      it "returns the user's profile social image URL" do
        expect(helper.profile_social_image_url(user)).to eq("https://example.com/user_profile.png")
      end
    end

    context "when user does not have a social image set" do
      it "returns the default main social image" do
        expect(helper.profile_social_image_url(user)).to eq(Settings::General.main_social_image.to_s)
      end
    end

    context "when organization has a social image set" do
      before do
        organization.update_column(:social_image, "https://example.com/org_profile.png")
      end

      it "returns the organization's social image URL" do
        expect(helper.profile_social_image_url(organization)).to eq("https://example.com/org_profile.png")
      end
    end

    context "when organization does not have a social image set" do
      it "returns the default main social image" do
        expect(helper.profile_social_image_url(organization)).to eq(Settings::General.main_social_image.to_s)
      end
    end
  end
end
