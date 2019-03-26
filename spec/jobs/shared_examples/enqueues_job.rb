RSpec.shared_examples "#enqueues_job" do |queue_name, args|
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        described_class.perform_later(*args)
      end.to have_enqueued_job.with(*args).on_queue(queue_name)
    end
  end
end
