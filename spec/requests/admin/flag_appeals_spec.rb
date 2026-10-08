require "rails_helper"

RSpec.describe "Admin::FlagAppeals" do
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

    it "creates a moderator audit log for the resolution" do
      Audit::Subscribe.listen(:moderator)

      expect do
        patch admin_flag_appeal_path(appeal), params: { resolution: "approve" }
      end.to change(AuditLog, :count).by(1)
      expect(AuditLog.last.data).to include("id" => appeal.id.to_s, "resolution" => "approve")

      Audit::Subscribe.forget(:moderator)
    end

    it "rejects the appeal when resolution=reject" do
      patch admin_flag_appeal_path(appeal), params: { resolution: "reject" }

      expect(response).to redirect_to(admin_flag_appeals_path(status: "rejected"))
      expect(appeal.reload.rejected?).to be true
    end

    it "blocks re-resolution when the appeal is already resolved" do
      appeal.update!(status: :approved, resolved_by: admin)
      allow(Appeals::Resolver).to receive(:approve)
      allow(Appeals::Resolver).to receive(:reject)

      patch admin_flag_appeal_path(appeal), params: { resolution: "reject" }

      expect(Appeals::Resolver).not_to have_received(:approve)
      expect(Appeals::Resolver).not_to have_received(:reject)
      expect(response).to redirect_to(admin_flag_appeals_path(status: "approved"))
      expect(flash[:alert]).to eq(I18n.t("admin.flag_appeals_controller.already_resolved"))
      expect(appeal.reload.approved?).to be true
    end

    it "reports already-resolved when another resolution wins the race after the status check" do
      allow(Appeals::Resolver).to receive(:approve).and_return(false)

      patch admin_flag_appeal_path(appeal), params: { resolution: "approve" }

      expect(response).to redirect_to(admin_flag_appeals_path(status: "open"))
      expect(flash[:alert]).to eq(I18n.t("admin.flag_appeals_controller.already_resolved"))
      expect(flash[:notice]).to be_nil
    end

    it "rejects unknown resolutions without resolving the appeal" do
      patch admin_flag_appeal_path(appeal), params: { resolution: "delete_everything" }

      expect(flash[:alert]).to eq(I18n.t("admin.flag_appeals_controller.invalid_action"))
      expect(appeal.reload.open?).to be true
    end
  end

  describe "authorization" do
    before { sign_in create(:user) }

    it "does not let a regular user view the queue" do
      expect { get admin_flag_appeals_path }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "does not let a regular user resolve an appeal" do
      expect do
        patch admin_flag_appeal_path(appeal), params: { resolution: "approve" }
      end.to raise_error(Pundit::NotAuthorizedError)

      expect(appeal.reload.open?).to be true
    end
  end

  describe "when the appealed content was deleted" do
    it "still renders the queue" do
      article = create(:article, user: user)
      create(:flag_appeal, user: user, appealable: article)
      article.delete

      get admin_flag_appeals_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Deleted from database")
    end
  end
end
