require "rails_helper"

RSpec.describe "Devices", type: :request do
  let(:user) { create(:user) }
  let(:consumer_app) { create(:consumer_app) }

  before do
    sign_in user
  end

  describe "POST /users/devices" do
    context "when device persisted" do
      it "increases device count" do
        post "/users/devices", params: {
          token: "123",
          platform: "Android",
          app_bundle: consumer_app.app_bundle
        }
        expect(user.devices.count).to eq(1)
        expect(response).to have_http_status(:created)
      end
    end

    context "when device not persisted" do
      let(:params) do
        {
          token: "123",
          platform: "unknown",
          app_bundle: consumer_app.app_bundle
        }
      end

      it "does not increase device count" do
        post "/users/devices", params: params
        expect(user.devices.count).to eq(0)
      end

      it "returns an error" do
        post "/users/devices", params: params
        expect(response.status).to eq(400)
        expect(response.body).to include("error")
      end
    end
  end

  describe "DELETE /users/devices/:id" do
    let(:device) { create(:device, user: user) }

    context "when device not found" do
      let(:incomplete_params) do
        {
          platform: device.platform,
          app_bundle: device.consumer_app.app_bundle
        }
      end

      it "returns an error" do
        delete "/users/devices/123"
        expect(response.status).to eq(404)
        expect(response.parsed_body["error"]).to eq("Not Found")
        expect(response.parsed_body["status"]).to eq(404)
      end

      it "return an error if device id doesn't match params" do
        delete "/users/devices/123", params: incomplete_params
        expect(response.status).to eq(404)
        expect(response.parsed_body["error"]).to eq("Not Found")
        expect(response.parsed_body["status"]).to eq(404)
      end
    end

    context "when device deleted" do
      let(:params) do
        {
          token: device.token,
          platform: device.platform,
          app_bundle: device.consumer_app.app_bundle
        }
      end

      it "deletes the device" do
        delete "/users/devices/#{device.user.id}", params: params
        expect(user.devices.count).to eq(0)
        expect(response.status).to eq(204)
        expect(Device.find_by(id: device.id)).to be_nil
      end
    end
  end
end
