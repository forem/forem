require "rails_helper"

RSpec.describe Users::SendAccountDeletedEmailWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", ["Name", "user@example.com"]

  describe "#perform" do
    before { allow(ForemInstance).to receive(:smtp_enabled?).and_return(true) }

    it "sends the account deleted email" do
      expect do
        described_class.new.perform("Name", "user@example.com")
      end.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(ActionMailer::Base.deliveries.last.to).to eq(["user@example.com"])
    end
  end
end
