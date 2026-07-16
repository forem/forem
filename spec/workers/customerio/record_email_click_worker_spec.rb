require "rails_helper"

RSpec.describe Customerio::RecordEmailClickWorker do
  describe "#perform" do
    let(:email_message) { create(:email_message, cio_delivery_id: "delivery-123", clicked_at: nil) }
    let(:event_timestamp) { 1_700_000_100 }

    it "sets clicked_at from the event timestamp when it was previously nil" do
      described_class.new.perform(email_message.cio_delivery_id, event_timestamp)

      expect(email_message.reload.clicked_at).to eq(Time.zone.at(event_timestamp))
    end

    it "preserves the existing clicked_at (first-click semantics)" do
      original_clicked_at = 1.day.ago.change(usec: 0)
      email_message.update_column(:clicked_at, original_clicked_at)

      described_class.new.perform(email_message.cio_delivery_id, event_timestamp)

      expect(email_message.reload.clicked_at).to eq(original_clicked_at)
    end

    it "no-ops without raising for an unknown delivery_id" do
      expect { described_class.new.perform("no-such-delivery-id", event_timestamp) }.not_to raise_error
    end
  end
end
