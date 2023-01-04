require "rails_helper"

RSpec.describe "users/edit" do
  let(:user) { create(:user) }
  let(:org)  { create(:organization) }

  describe "/settings/organization" do
    before do
      sign_in user
      assign(:user, user)
      assign(:tab, "organization")
    end

    context "when the user is an org admin" do
      before do
        org_membership = create(:organization_membership, user: user, organization: org, type_of_user: "admin")
        assign(:organizations, user.organizations)
        assign(:organization, org)
        assign(:organization_membership, org_membership)
        assign(:org_organization_memberships, org.organization_memberships)
      end

      it "shows the org admin page" do
        render
        expect(rendered).to have_text("Grow the team")
      end

      it "shows the destroy button if the org has one admin and no content" do
        render
        expect(rendered).to have_css(".crayons-btn--danger")
      end

      it "shows the proper message if the org has more than one member" do
        second_user = create(:user)
        create(:organization_membership, user: second_user, organization: org)
        assign(:org_organization_memberships, org.organization_memberships)
        render
        expect(rendered).to have_text("Your organization currently does not meet the above requirements.")
      end

      it "shows the proper message if the org has an article" do
        allow(org).to receive(:articles_count).and_return(1)
        render
        expect(rendered).to have_text("Your organization currently does not meet the above requirements.")
      end
    end
  end
end
