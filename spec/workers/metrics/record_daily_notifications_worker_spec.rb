require "rails_helper"

RSpec.describe Metrics::RecordDailyNotificationsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    let(:user) { create(:user) }
    let!(:ahoy_event) { create(:ahoy_event) }
    let(:event_title_count) { Metrics::RecordDailyNotificationsWorker::EVENT_TITLES.count }

    before do
      allow(ForemStatsClient).to receive(:count)
      ahoy_event
      described_class.new.perform
    end

    it "logs welcome notification click events created in the past day" do
      expect(ForemStatsClient).to have_received(:count).exactly(event_title_count).times
      expect(
        ForemStatsClient,
      ).to have_received(:count)
        .with("ahoy_events", 1, { tags: ["title:welcome_notification_welcome_thread"] })
        .at_least(1)
    end
  end
end
