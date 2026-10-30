require "rails_helper"

RSpec.describe "Articles::Manage pinning sections" do
  let(:organization) { create(:organization) }
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author, organization: organization) }

  before do
    create(:organization_membership, organization: organization, user: author, type_of_user: "admin")
    sign_in author
  end

  describe "GET /:username/:slug/manage" do
    context "when the article has an Organization pin but no User pin" do
      before do
        create(:profile_pin, :for_organization, pinnable: article, profile: organization)
      end

      it "still offers to pin the article to the author's own profile" do
        get "#{article.path}/manage"

        expect(response.body).to include("Pin to Profile")
        expect(response.body).not_to include("This post is currently pinned to your profile.")
      end

      it "shows the article as pinned to the organization" do
        get "#{article.path}/manage"

        expect(response.body).to include("This post is currently pinned to #{organization.name}.")
      end
    end

    context "when the article has both a User pin and an Organization pin" do
      before do
        create(:profile_pin, pinnable: article, profile: author)
        create(:profile_pin, :for_organization, pinnable: article, profile: organization)
      end

      it "reports the article as pinned to the author's profile, not the org pin" do
        get "#{article.path}/manage"

        expect(response.body).to include("This post is currently pinned to your profile.")
      end
    end
  end

  describe "Article#user_profile_pins" do
    it "excludes Organization pins" do
      create(:profile_pin, :for_organization, pinnable: article, profile: organization)

      expect(article.user_profile_pins).to be_empty
      expect(article.profile_pins.size).to eq(1)
    end

    it "includes only the article's own User pin" do
      user_pin = create(:profile_pin, pinnable: article, profile: author)
      create(:profile_pin, :for_organization, pinnable: article, profile: organization)

      expect(article.user_profile_pins).to contain_exactly(user_pin)
    end
  end

  describe "stale organization pins are removed when an article's organization changes" do
    it "deletes the Organization pin when the article moves to another organization" do
      create(:profile_pin, :for_organization, pinnable: article, profile: organization)
      other_org = create(:organization)

      expect do
        article.update!(organization: other_org)
      end.to change { ProfilePin.where(profile_type: "Organization", pinnable: article).count }.from(1).to(0)
    end

    it "deletes the Organization pin when the article becomes a personal post" do
      create(:profile_pin, :for_organization, pinnable: article, profile: organization)

      expect do
        article.update!(organization: nil)
      end.to change { ProfilePin.where(profile_type: "Organization", pinnable: article).count }.from(1).to(0)
    end

    it "does not remove the pin when unrelated attributes change" do
      create(:profile_pin, :for_organization, pinnable: article, profile: organization)

      expect do
        article.update!(title: "A brand new title")
      end.not_to change { ProfilePin.where(profile_type: "Organization", pinnable: article).count }
    end
  end
end
