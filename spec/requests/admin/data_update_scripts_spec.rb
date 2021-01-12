require "rails_helper"

RSpec.describe "/admin/data_update_scripts", type: :request do
  let(:get_resource) { get "/admin/data_update_scripts" }

  context "when the user is not an tech admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /admin/data_update_scripts" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(StandardError)
      end
    end
  end

  context "when the user is a tech admin" do
    let(:user) { create(:user, :admin, :tech_admin) }

    before { sign_in user }

    describe "GET /admin/data_update_scripts" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end

      it "displays the data_update_scripts" do
        script = create(:data_update_script)
        get_resource

        expect(response.body).to include(script.id.to_s)
        expect(response.body).to include(script.run_at.to_s)
        expect(response.body).to include(script.created_at.to_s)
        expect(response.body).to include(script.status.to_s)
      end
    end
  end
end
