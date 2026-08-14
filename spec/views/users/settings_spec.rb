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
        create(:organization_membership, user: user, organization: org, type_of_user: "admin")
        assign(:organizations, user.organizations)
        assign(:organization, Organization.new)
      end

      it "shows the org listing with settings link" do
        render
        expect(rendered).to have_text(I18n.t("views.settings.org.list.heading"))
        expect(rendered).to have_link(I18n.t("views.settings.org.list.manage"))
      end

      it "shows the create organization section" do
        render
        expect(rendered).to have_text(I18n.t("views.settings.org.create.heading"))
      end

      it "shows the join organization section" do
        render
        expect(rendered).to have_text(I18n.t("views.settings.org.join.heading"))
      end
    end

    context "when the user is a non-admin member" do
      before do
        create(:organization_membership, user: user, organization: org, type_of_user: "member")
        assign(:organizations, user.organizations)
        assign(:organization, Organization.new)
      end

      it "shows the org listing with leave button" do
        render
        expect(rendered).to have_text(I18n.t("views.settings.org.list.heading"))
        expect(rendered).to have_button(I18n.t("views.settings.org.leave.submit"))
      end
    end
  end
end
