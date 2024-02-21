require "rails_helper"

RSpec.describe PageViewRollupWorker, type: :worker do
  subject(:worker) { described_class.new }

  before do
    allow(PageViewRollup).to receive(:rollup)
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    it "rollups five month ago" do
      five_month_ago = Date.current - 5.months
      worker.perform
      expect(PageViewRollup).to have_received(:rollup).with(five_month_ago)
    end
  end
end
