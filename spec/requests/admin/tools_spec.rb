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

  describe "POST /admin/advanced/tools/reprocess_image_host" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    it "enqueues the worker and redirects with a success flash" do
      allow(Articles::ReprocessByImageHostWorker).to receive(:perform_async)

      post reprocess_image_host_admin_tools_path, params: {
        image_host: "cdn.hashnode.com",
        image_host_limit: "10",
        image_host_since: "2026-01-01"
      }

      expect(Articles::ReprocessByImageHostWorker).to have_received(:perform_async)
        .with("cdn.hashnode.com", 10, "2026-01-01")
      expect(response).to redirect_to(admin_tools_path)
      expect(flash[:success]).to include("cdn.hashnode.com")
    end

    it "passes nil when image_host_since is blank" do
      allow(Articles::ReprocessByImageHostWorker).to receive(:perform_async)

      post reprocess_image_host_admin_tools_path, params: { image_host: "cdn.hashnode.com", image_host_limit: "10" }

      expect(Articles::ReprocessByImageHostWorker).to have_received(:perform_async)
        .with("cdn.hashnode.com", 10, nil)
    end

    it "flashes danger when image_host is blank" do
      post reprocess_image_host_admin_tools_path, params: { image_host: "" }

      expect(response).to redirect_to(admin_tools_path)
      expect(flash[:danger]).to be_present
    end
  end
end
