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

      it "shows the org listing with settings link, create section, and join section", :aggregate_failures do
        render
        expect(rendered).to have_text(I18n.t("views.settings.org.list.heading"))
        expect(rendered).to have_link(I18n.t("views.settings.org.list.manage"))
        expect(rendered).to have_text(I18n.t("views.settings.org.create.heading"))
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

    context "when editing a specific organization's settings" do
      let(:org) { create(:organization, bg_color_hex: "#e036c4", text_color_hex: "") }

      before do
        membership = create(:organization_membership, user: user, organization: org, type_of_user: "admin")
        assign(:tab, "org-admin")
        assign(:organization, org)
        assign(:organization_membership, membership)
        assign(:org_organization_memberships, [membership])
      end

      it "renders the logo color preview and preserves bg_color_hex", :aggregate_failures do
        render
        expect(rendered).to have_css(
          'input#organization_bg_color_hex[value="#e036c4"][data-preview-property="backgroundColor"]',
        )
        expect(rendered).to have_css(
          'input#organization_text_color_hex[value="#ffffff"][data-preview-property="fill"]',
        )
        expect(rendered).to have_css(
          'svg#color-select-preview-logo[data-default-bg-color="#0a0a0a"][data-default-text-color="#ffffff"]',
        )
        expect(rendered).to have_css(
          'svg#color-select-preview-logo[style*="background-color: #e036c4;"][style*="fill: #ffffff;"]',
        )
      end
    end
  end
end
