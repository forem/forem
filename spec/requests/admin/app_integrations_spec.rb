require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/app_integrations", type: :request do
  let!(:app_integration) { create(:app_integration) }
  let(:get_resource) { get "/admin/app_integrations" }
  let(:params) do
    {
      app_bundle: app_integration.app_bundle,
      platform: Device::IOS,
      auth_key: "sample_data"
    }
  end
  let(:post_resource) { post "/admin/app_integrations", params: params }

  it_behaves_like "an InternalPolicy dependant request", AppIntegration do
    let(:request) { get_resource }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /admin/app_integrations" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/app_integrations" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    describe "GET /admin/app_integrations" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/app_integrations" do
      it "creates a new app_integration" do
        expect do
          post_resource
        end.to change { AppIntegration.all.count }.by(1)
      end
    end

    describe "PUT /admin/app_integrations" do
      let!(:app_integration) { create(:app_integration, app_bundle: "com.bundle.test") }

      it "updates the AppIntegration" do
        put "/admin/app_integrations/#{app_integration.id}", params: params
        app_integration.reload
        expect(app_integration.app_bundle).to eq(params[:app_bundle])
        expect(app_integration.platform).to eq(params[:platform])
        expect(app_integration.auth_key).to eq(params[:auth_key])
      end
    end

    describe "DELETE /admin/app_integrations/:id" do
      let!(:app_integration) { create(:app_integration) }

      it "deletes the AppIntegration" do
        expect do
          delete "/admin/app_integrations/#{app_integration.id}"
        end.to change { AppIntegration.all.count }.by(-1)
        expect(response.body).to redirect_to "/admin/app_integrations"
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: AppIntegration) }

    before { sign_in single_resource_admin }

    describe "GET /admin/app_integrations" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/app_integrations" do
      it "creates a new AppIntegration" do
        expect do
          post_resource
        end.to change { AppIntegration.all.count }.by(1)
      end
    end

    describe "PUT /admin/app_integrations" do
      let!(:app_integration) { create(:app_integration, app_bundle: "com.bundle.test") }

      it "updates the AppIntegration" do
        put "/admin/app_integrations/#{app_integration.id}", params: params
        app_integration.reload
        expect(app_integration.app_bundle).to eq(params[:app_bundle])
        expect(app_integration.platform).to eq(params[:platform])
        expect(app_integration.auth_key).to eq(params[:auth_key])
      end
    end

    describe "DELETE /admin/app_integrations/:id" do
      let!(:app_integration) { create(:app_integration) }

      it "deletes the AppIntegration" do
        expect do
          delete "/admin/app_integrations/#{app_integration.id}"
        end.to change { AppIntegration.all.count }.by(-1)
        expect(response.body).to redirect_to "/admin/app_integrations"
      end
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before { sign_in single_resource_admin }

    describe "GET /admin/app_integrations" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/app_integrations" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
