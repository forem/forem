require "rails_helper"

RSpec.describe "/admin/content_manager/organizations verified" do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization, verified: false) }

  before do
    sign_in(admin)
  end

  describe "PATCH /admin/organizations/:id/update_verified" do
    it "enables verified status" do
      expect do
        patch update_verified_admin_organization_path(organization),
              params: { verified: "true" }
      end.to change { organization.reload.verified }.from(false).to(true)

      expect(organization.verified_at).to be_present
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("verified")
    end

    it "disables verified status" do
      organization.update(verified: true, verified_at: Time.current)

      expect do
        patch update_verified_admin_organization_path(organization),
              params: { verified: "false" }
      end.to change { organization.reload.verified }.from(true).to(false)

      expect(organization.verified_at).to be_nil
      expect(organization.verification_url).to be_nil
      expect(response).to redirect_to(admin_organization_path(organization))
    end

    it "creates a note when verifying" do
      expect do
        patch update_verified_admin_organization_path(organization),
              params: { verified: "true" }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.noteable).to eq(organization)
      expect(note.author).to eq(admin)
      expect(note.content).to include("enabled")
    end

    it "creates a note when revoking verification" do
      organization.update(verified: true, verified_at: Time.current)

      expect do
        patch update_verified_admin_organization_path(organization),
              params: { verified: "false" }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.content).to include("disabled")
    end
  end
end
