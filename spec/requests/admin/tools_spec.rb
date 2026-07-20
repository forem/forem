require "rails_helper"

RSpec.describe "/admin/advanced/tools" do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get admin_tools_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before do
      sign_in super_admin
      get admin_tools_path
    end

    it "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Tool) }

    before do
      sign_in single_resource_admin
      get admin_tools_path
    end

    it "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before do
      sign_in single_resource_admin
    end

    it "blocks the request" do
      expect do
        get admin_tools_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "POST /admin/advanced/tools/regenerate_social_images" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:target_user) { create(:user) }

    before do
      sign_in super_admin
    end

    context "with a valid user_id" do
      it "enqueues the worker and redirects with success" do
        allow(Images::SocialImageWorker).to receive(:perform_async)

        post regenerate_social_images_admin_tools_path, params: { user_id: target_user.id.to_s }

        expect(Images::SocialImageWorker).to have_received(:perform_async).with(target_user.id, "User")

        expect(response).to redirect_to(admin_tools_path)
        expect(flash[:success]).to eq(I18n.t("admin.tools_controller.social_images_queued", user: target_user.username))
      end
    end

    context "with an invalid user_id" do
      it "redirects with error" do
        post regenerate_social_images_admin_tools_path, params: { user_id: "0" }

        expect(response).to redirect_to(admin_tools_path)
        expect(flash[:danger]).to eq(I18n.t("admin.tools_controller.user_not_found"))
      end
    end
  end
end
