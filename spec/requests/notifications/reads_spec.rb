require "rails_helper"

RSpec.describe "Notifications::Reads", type: :request do
  describe "POST /notifications/reads" do
    let(:stubbed_service_object) { double }

    before do
      sign_in create(:user)
      allow(ReadNotificationsService).to receive(:new).and_return(stubbed_service_object)
      allow(stubbed_service_object).to receive(:mark_as_read)
    end

    it "works! (now write some real specs)" do
      post "/notifications/reads/"
      expect(response).to have_http_status(:ok)
      expect(stubbed_service_object).to have_received(:mark_as_read).once
    end

    it "works with org Id too" do
      post "/notifications/reads/", params: { org_id: 1 }
      expect(response).to have_http_status(:ok)
      expect(stubbed_service_object).to have_received(:mark_as_read).twice
    end
  end
end
