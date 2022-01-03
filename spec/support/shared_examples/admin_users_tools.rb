require "view_component/test_helpers"

RSpec.shared_examples "Admin::Users::Tools::ShowAction" do |path_helper, component|
  include ViewComponent::TestHelpers

  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "#show" do
    let(:user) { create(:user) }

    it "returns not found for non existing users" do
      expect { get public_send(path_helper, 9999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders successfully" do
      get public_send(path_helper, user)

      expect(response).to have_http_status(:ok)
    end

    it "returns HTML" do
      get public_send(path_helper, user)

      expect(response.media_type).to eq("text/html")
    end

    it "renders the EmailsComponent" do
      get public_send(path_helper, user)

      render_inline(component.new(user: user))

      expect(response.body).to eq(rendered_component)
    end
  end
end
