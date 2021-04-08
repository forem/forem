require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/push_notification_targets", type: :request do
  let(:get_resource) { get "/admin/push_notification_targets" }
  let(:params) do
    {
      app_bundle: "com.app.lol",
      platform: Device::IOS,
      auth_key: "sample_data"
    }
  end
  let(:post_resource) { post "/admin/push_notification_targets", params: params }

  it_behaves_like "an InternalPolicy dependant request", PushNotificationTarget do
    let(:request) { get_resource }
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /admin/push_notification_targets" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/push_notification_targets" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before { sign_in super_admin }

    describe "GET /admin/push_notification_targets" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/push_notification_targets" do
      it "creates a new push_notification_target" do
        expect do
          post_resource
        end.to change { PushNotificationTarget.all.count }.by(1)
      end
    end

    describe "PUT /admin/push_notification_targets" do
      let!(:push_notification_target) { create(:push_notification_target, app_bundle: "com.bundle.test") }

      it "updates the PushNotificationTarget" do
        put "/admin/push_notification_targets/#{push_notification_target.id}", params: params
        push_notification_target.reload
        expect(push_notification_target.app_bundle).to eq(params[:app_bundle])
        expect(push_notification_target.platform).to eq(params[:platform])
        expect(push_notification_target.auth_key).to eq(params[:auth_key])
      end
    end

    describe "DELETE /admin/push_notification_targets/:id" do
      let!(:push_notification_target) { create(:push_notification_target) }

      it "deletes the Push Notification Target" do
        expect do
          delete "/admin/push_notification_targets/#{push_notification_target.id}"
        end.to change { PushNotificationTarget.all.count }.by(-1)
        expect(response.body).to redirect_to "/admin/push_notification_targets"
      end
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: PushNotificationTarget) }

    before { sign_in single_resource_admin }

    describe "GET /admin/push_notification_targets" do
      it "allows the request" do
        get_resource
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/push_notification_targets" do
      it "creates a new push_notification_target" do
        expect do
          post_resource
        end.to change { PushNotificationTarget.all.count }.by(1)
      end
    end

    describe "PUT /admin/push_notification_targets" do
      let!(:push_notification_target) { create(:push_notification_target, app_bundle: "com.bundle.test") }

      it "updates the PushNotificationTarget" do
        put "/admin/push_notification_targets/#{push_notification_target.id}", params: params
        push_notification_target.reload
        expect(push_notification_target.app_bundle).to eq(params[:app_bundle])
        expect(push_notification_target.platform).to eq(params[:platform])
        expect(push_notification_target.auth_key).to eq(params[:auth_key])
      end
    end

    describe "DELETE /admin/push_notification_targets/:id" do
      let!(:push_notification_target) { create(:push_notification_target) }

      it "deletes the Push Notification Target" do
        expect do
          delete "/admin/push_notification_targets/#{push_notification_target.id}"
        end.to change { PushNotificationTarget.all.count }.by(-1)
        expect(response.body).to redirect_to "/admin/push_notification_targets"
      end
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before { sign_in single_resource_admin }

    describe "GET /admin/push_notification_targets" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/push_notification_targets" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
