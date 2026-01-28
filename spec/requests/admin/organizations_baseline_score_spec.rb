require "rails_helper"

RSpec.describe "Update Organization Baseline Score", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization, baseline_score: 0) }

  before do
    sign_in(super_admin)
  end

  describe "PATCH /admin/content_manager/organizations/:id/update_baseline_score" do
    it "updates the baseline_score successfully" do
      expect(organization.baseline_score).to eq(0)

      patch update_baseline_score_admin_organization_path(organization), params: { baseline_score: 50 }

      organization.reload
      expect(organization.baseline_score).to eq(50)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("Baseline score updated")
    end

    it "creates an audit note for the change" do
      expect do
        patch update_baseline_score_admin_organization_path(organization), params: { baseline_score: 100 }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.noteable).to eq(organization)
      expect(note.content).to include("Baseline score changed from 0 to 100")
      expect(note.author_id).to eq(super_admin.id)
    end

    it "works when updating from a non-zero value" do
      organization.update(baseline_score: 20)

      patch update_baseline_score_admin_organization_path(organization), params: { baseline_score: 0 }

      organization.reload
      expect(organization.baseline_score).to eq(0)
    end

    it "raises an error for negative values" do
      expect do
        patch update_baseline_score_admin_organization_path(organization), params: { baseline_score: -5 }
      end.to raise_error(ActiveRecord::RecordInvalid)
      
      organization.reload
      expect(organization.baseline_score).to eq(0)
    end
  end
end
