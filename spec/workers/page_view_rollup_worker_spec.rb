require "rails_helper"

RSpec.describe PageViewRollupWorker, type: :worker do
  subject(:worker) { described_class.new }

  before do
    allow(PageViewRollup).to receive(:rollup)
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    it "rolls up one year ago" do
      Timecop.freeze do
        one_year_ago = 1.year.ago
        worker.perform
        expect(PageViewRollup).to have_received(:rollup).with(one_year_ago)
      end
    end
  end
end
