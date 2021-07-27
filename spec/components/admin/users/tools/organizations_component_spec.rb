require "rails_helper"

RSpec.describe Admin::Users::Tools::OrganizationsComponent, type: :component do
  let(:user) { create(:user) }

  describe "Add new org membership" do
    it "renders the section", :aggregate_failures do
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("Add #{user.name} to a new organization")
      expect(rendered_component).to have_css("form[action='#{admin_organization_memberships_path}']")
    end
  end

  describe "Manage memberships" do
    it "does not render the section by default" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).not_to have_text("Manage memberships")
    end

    it "renders the section if the user belongs to an organization", :aggregate_failures do
      membership = create(:organization_membership, user: user)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text(membership.organization.name)
      expect(rendered_component).to have_css("input[value='delete']", visible: :hidden)
    end
  end
end
