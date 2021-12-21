require "rails_helper"

RSpec.describe Webhook::DestroyWorker, type: :worker do
  let(:user) { create(:user) }
  let!(:webhook_endpoint) { create(:webhook_endpoint, user: user) }
  let!(:other_webhook_endpoint) { create(:webhook_endpoint) }
  let(:worker) { subject }

  describe "#perform_now" do
    xit "destroys webhook by user_id and app_id" do
      worker.perform(user.id)
      expect(Webhook::Endpoint.find_by(id: webhook_endpoint.id)).to be_nil
      expect(other_webhook_endpoint.reload).to be_present
    end
  end
end
