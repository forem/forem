require "rails_helper"

RSpec.describe "Admin::FlagAppeals", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let!(:appeal) { create(:flag_appeal, user: user, appealable: user) }

  before { sign_in admin }

  describe "GET /admin/moderation/flag_appeals" do
    it "renders the index queue page" do
      get admin_flag_appeals_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Flag Appeals Queue")
    end
  end

  describe "GET /admin/moderation/flag_appeals/:id" do
    it "renders the show appeal details page" do
      get admin_flag_appeal_path(appeal)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Flag Appeal ##{appeal.id}")
    end
  end

  describe "PATCH /admin/moderation/flag_appeals/:id" do
    it "approves the appeal when resolution=approve" do
      patch admin_flag_appeal_path(appeal), params: { resolution: "approve" }

      expect(response).to redirect_to(admin_flag_appeals_path(status: "approved"))
      expect(appeal.reload.approved?).to be true
    end

    it "rejects the appeal when resolution=reject" do
      patch admin_flag_appeal_path(appeal), params: { resolution: "reject" }

      expect(response).to redirect_to(admin_flag_appeals_path(status: "rejected"))
      expect(appeal.reload.rejected?).to be true
    end

    it "blocks re-resolution when the appeal is already resolved" do
      appeal.update!(status: :approved, resolved_by: admin)

      expect(Appeals::Resolver).not_to receive(:approve)
      expect(Appeals::Resolver).not_to receive(:reject)

      patch admin_flag_appeal_path(appeal), params: { resolution: "reject" }

      expect(response).to redirect_to(admin_flag_appeals_path(status: "approved"))
      expect(flash[:alert]).to eq(I18n.t("admin.flag_appeals_controller.already_resolved"))
      expect(appeal.reload.approved?).to be true
    end
  end
end
