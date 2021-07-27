require "rails_helper"
require "view_component/test_helpers"

RSpec.describe "/admin/users/:user_id/tools", type: :request do
  include ViewComponent::TestHelpers

  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "#show" do
    let(:user) { create(:user) }

    it "returns not found for non existing users" do
      expect { get admin_user_tools_path(9999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders successfully" do
      get admin_user_tools_path(user)

      expect(response).to have_http_status(:ok)
    end

    it "returns HTML" do
      get admin_user_tools_path(user)

      expect(response.media_type).to eq("text/html")
    end

    it "renders the ToolsComponent" do
      get admin_user_tools_path(user)

      render_inline(Admin::Users::ToolsComponent.new(user: user))

      expect(response.body).to eq(rendered_component)
    end
  end
end
