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

    it "skips Subforem score updates when Subforem.disabled_by_env? is true" do
      create(:subforem, domain: "dev.to")
      allow(Subforem).to receive(:disabled_by_env?).and_return(true)
      allow(Subforem).to receive(:find_each)

      worker.perform

      expect(Subforem).not_to have_received(:find_each)
    end
  end
end
