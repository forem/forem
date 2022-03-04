require "rails_helper"

RSpec.describe "/admin/apps/welcome", type: :request do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get admin_welcome_index_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before do
      sign_in super_admin
      get admin_welcome_index_path
    end

    it "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Welcome) }

    before do
      sign_in single_resource_admin
      get admin_welcome_index_path
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
        get admin_welcome_index_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  # Regression test for https://github.com/forem/forem/issues/14315
  it "renders the editor to create a welcome thread" do
    admin = create(:user, :super_admin)
    sign_in admin
    allow(Settings::Community).to receive(:staff_user_id).and_return(admin.id)

    post admin_welcome_index_path

    expect(response).to have_http_status(:found)
    follow_redirect!
    expect(response.body).to match(/Introduce yourself to the community/)
  end
end
