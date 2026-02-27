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

    describe "POST /admin/advanced/tools/run_data_fix" do
      before do
        allow(DataFixes::RunWorker).to receive(:perform_async)
      end

      it "enqueues the selected data fix" do
        post run_data_fix_admin_tools_path, params: { fix_name: DataFixes::FixTagCounts::KEY }

        expect(response).to redirect_to(admin_tools_path)
        expect(DataFixes::RunWorker).to have_received(:perform_async).with(DataFixes::FixTagCounts::KEY,
                                                                           super_admin.id)
      end

      it "does not enqueue unknown data fixes" do
        post run_data_fix_admin_tools_path, params: { fix_name: "unknown_fix" }

        expect(response).to redirect_to(admin_tools_path)
        expect(DataFixes::RunWorker).not_to have_received(:perform_async)
      end
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
end
