require "rails_helper"

RSpec.describe Webhook::DestroyWorker, type: :worker do
  let(:user) { create(:user) }
  let(:oauth_app) { create(:application) }
  let!(:webhook_endpoint) { create(:webhook_endpoint, user: user, oauth_application: oauth_app) }
  let!(:other_webhook_endpoint) { create(:webhook_endpoint, oauth_application: oauth_app) }
  let(:worker) { subject }

  describe "#perform_now" do
    it "destrous webhook by user_id and app_id" do
      worker.perform(user.id, oauth_app.id)
      expect(Webhook::Endpoint.find_by(id: webhook_endpoint.id)).to be_nil
      expect(other_webhook_endpoint.reload).to be_present
    end
  end
end
