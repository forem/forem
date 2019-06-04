require "rails_helper"

RSpec.describe "Notifications::Reads", type: :request do
  describe "POST /notifications/reads" do
    let(:stubbed_service_object) { double }
    let(:user) { create(:user) }

    before do
      sign_in user
      allow(ReadNotificationsService).to receive(:new).and_return(stubbed_service_object)
      allow(stubbed_service_object).to receive(:mark_as_read)
    end

    it "marks notifications as read" do
      post "/notifications/reads/"
      expect(response).to have_http_status(:ok)
      expect(stubbed_service_object).to have_received(:mark_as_read).once
    end

    it "marks personal and org notifications as read" do
      org_admin = create(:user, :org_admin)
      org_id = org_admin.organizations.first.id
      sign_in org_admin
      post "/notifications/reads/", params: { org_id: org_id }
      expect(response).to have_http_status(:ok)
      expect(stubbed_service_object).to have_received(:mark_as_read).twice
    end
  end
end
