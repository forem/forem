require "rails_helper"

RSpec.describe "OrganizationProfilePins" do
  let(:organization) { create(:organization) }
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:outsider) { create(:user) }
  let(:article) { create(:article, organization: organization, user: admin) }
  let(:article2) { create(:article, organization: organization, user: admin) }
  let(:article3) { create(:article, organization: organization, user: admin) }
  let(:article4) { create(:article, organization: organization, user: admin) }
  let(:article5) { create(:article, organization: organization, user: admin) }
  let(:article6) { create(:article, organization: organization, user: admin) }

  before do
    create(:organization_membership, organization: organization, user: admin, type_of_user: "admin")
    create(:organization_membership, organization: organization, user: member, type_of_user: "member")
  end

  describe "POST /:slug/profile_pins" do
    context "when signed in as an organization admin" do
      before { sign_in admin }

      it "creates an organization pin for an article belonging to the organization" do
        post "/#{organization.slug}/profile_pins", params: { profile_pin: { pinnable_id: article.id } }
        pin = ProfilePin.last
        expect(pin.pinnable_id).to eq(article.id)
        expect(pin.profile_type).to eq("Organization")
        expect(pin.profile_id).to eq(organization.id)
      end

      it "allows only five pins per organization" do
        [article, article2, article3, article4, article5, article6].each do |a|
          post "/#{organization.slug}/profile_pins", params: { profile_pin: { pinnable_id: a.id } }
        end
        expect(organization.reload.profile_pins.size).to eq(5)
      end

      it "does not pin an article that belongs to a different organization" do
        other_org_article = create(:article, organization: create(:organization), user: admin)
        post "/#{organization.slug}/profile_pins", params: { profile_pin: { pinnable_id: other_org_article.id } }
        expect(organization.reload.profile_pins.size).to eq(0)
      end
    end

    context "when signed in as a regular organization member (not admin)" do
      before { sign_in member }

      it "is not authorized" do
        expect do
          post "/#{organization.slug}/profile_pins", params: { profile_pin: { pinnable_id: article.id } }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when signed in as a user unaffiliated with the organization" do
      before { sign_in outsider }

      it "is not authorized" do
        expect do
          post "/#{organization.slug}/profile_pins", params: { profile_pin: { pinnable_id: article.id } }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when not signed in" do
      it "does not create a pin and redirects away" do
        post "/#{organization.slug}/profile_pins", params: { profile_pin: { pinnable_id: article.id } }
        expect(response).to have_http_status(:redirect)
        expect(ProfilePin.count).to eq(0)
      end
    end
  end

  describe "DELETE /:slug/profile_pins/:id" do
    it "removes the organization's pin" do
      sign_in admin
      pin = create(:profile_pin, :for_organization, pinnable: article, profile: organization)
      delete "/#{organization.slug}/profile_pins/#{pin.id}"
      expect(ProfilePin.exists?(pin.id)).to be false
    end
  end
end
