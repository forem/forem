require "rails_helper"

RSpec.describe "/admin/content_manager/organizations fully_trusted" do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization, fully_trusted: false) }

  before do
    sign_in(admin)
  end

  describe "PATCH /admin/organizations/:id/update_fully_trusted" do
    it "enables fully_trusted status" do
      expect do
        patch update_fully_trusted_admin_organization_path(organization),
              params: { fully_trusted: "true" }
      end.to change { organization.reload.fully_trusted }.from(false).to(true)

      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("enabled")
    end

    it "disables fully_trusted status" do
      organization.update(fully_trusted: true)

      expect do
        patch update_fully_trusted_admin_organization_path(organization),
              params: { fully_trusted: "false" }
      end.to change { organization.reload.fully_trusted }.from(true).to(false)

      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("disabled")
    end

    it "creates a note when updating" do
      expect do
        patch update_fully_trusted_admin_organization_path(organization),
              params: { fully_trusted: "true" }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.noteable).to eq(organization)
      expect(note.author).to eq(admin)
    end
  end
end

