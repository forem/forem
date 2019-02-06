require "rails_helper"

RSpec.describe Articles::ScoreCalcJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        described_class.perform_later(1)
      end.to have_enqueued_job.with(1).on_queue("articles_score_calc")
    end
  end
end
