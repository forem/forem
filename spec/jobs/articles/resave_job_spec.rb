require "rails_helper"

RSpec.describe Articles::ResaveJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        Articles::ResaveJob.perform_later([1, 2])
      end.to have_enqueued_job.with([1, 2]).on_queue("articles_resave")
    end
  end
end
