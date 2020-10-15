require "rails_helper"

RSpec.describe Tags::ResaveSupportedTagsWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    it "resaves supported tags" do
      Timecop.freeze do
        old_update_timestamp = 1.week.ago
        tag = create(:tag, supported: true, updated_at: old_update_timestamp)

        worker.perform

        expect(tag.updated_at).to be > old_update_timestamp
      end
    end
  end
end
