require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe Rails.application.routes.url_helpers.admin_consumer_apps_path.to_s, type: :request do
  let(:get_resource) { get admin_consumer_apps_path }
  let(:params) do
    {
      app_bundle: Faker::Internet.domain_name(subdomain: true),
      platform: Device::IOS,
      auth_key: "sample_data"
    }
  end
  let(:post_resource) { post admin_consumer_apps_path, params: params }

  it_behaves_like "an InternalPolicy dependant request", ConsumerApp do
    let(:request) { get_resource }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    describe "GET #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      it "creates a new consumer_app" do
        expect do
          post_resource
        end.to change { ConsumerApp.all.count }.by(1)
      end
    end

    describe "PUT #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      let!(:consumer_app) { create(:consumer_app, app_bundle: "com.bundle.test") }

      it "updates the ConsumerApp" do
        put admin_consumer_app_path(consumer_app.id), params: params
        consumer_app.reload
        expect(consumer_app.app_bundle).to eq(params[:app_bundle])
        expect(consumer_app.platform).to eq(params[:platform])
        expect(consumer_app.auth_key).to eq(params[:auth_key])
      end
    end

    describe "DELETE #{Rails.application.routes.url_helpers.admin_consumer_apps_path}/:id" do
      let!(:consumer_app) { create(:consumer_app) }

      it "deletes the ConsumerApp" do
        expect do
          delete admin_consumer_app_path(consumer_app.id)
        end.to change { ConsumerApp.all.count }.by(-1)
        expect(response.body).to redirect_to admin_consumer_apps_path
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: ConsumerApp) }

    before { sign_in single_resource_admin }

    describe "GET #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      it "creates a new ConsumerApp" do
        expect do
          post_resource
        end.to change { ConsumerApp.all.count }.by(1)
      end

      it "fails when trying to create duplicate apps (app_bundle + platform)" do
        expect do
          post_resource
          post_resource
        end.to change { ConsumerApp.all.count }.by(1)
      end
    end

    describe "PUT #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      let!(:consumer_app) { create(:consumer_app, app_bundle: "com.bundle.test") }

      it "updates the ConsumerApp" do
        put admin_consumer_app_path(consumer_app.id), params: params
        consumer_app.reload
        expect(consumer_app.app_bundle).to eq(params[:app_bundle])
        expect(consumer_app.platform).to eq(params[:platform])
        expect(consumer_app.auth_key).to eq(params[:auth_key])
      end
    end

    describe "DELETE #{Rails.application.routes.url_helpers.admin_consumer_apps_path}/:id" do
      let!(:consumer_app) { create(:consumer_app) }

      it "deletes the ConsumerApp" do
        expect do
          delete admin_consumer_app_path(consumer_app.id)
        end.to change { ConsumerApp.all.count }.by(-1)
        expect(response.body).to redirect_to admin_consumer_apps_path
      end
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before { sign_in single_resource_admin }

    describe "GET #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST #{Rails.application.routes.url_helpers.admin_consumer_apps_path}" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
