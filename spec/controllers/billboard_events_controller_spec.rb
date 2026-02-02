require "rails_helper"

RSpec.describe BillboardEventsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:billboard) { create(:billboard, approved: true, published: true) }

  before do
    sign_in user
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        billboard_event: {
          billboard_id: billboard.id,
          context_type: "home",
          category: "impression"
        }
      }
    end

    context "when creating an impression event" do
      it "enqueues the DataUpdateWorker for processing" do
        expect(Billboards::DataUpdateWorker).to receive(:perform_async).with(billboard.id.to_s)
        post :create, params: valid_params
        expect(response).to have_http_status(:ok)
      end
    end

    context "when creating a non-impression event" do
      let(:click_params) do
        {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: "home",
            category: "click"
          }
        }
      end

      it "enqueues the DataUpdateWorker for processing" do
        expect(Billboards::DataUpdateWorker).to receive(:perform_async).with(billboard.id.to_s)
        post :create, params: click_params
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
