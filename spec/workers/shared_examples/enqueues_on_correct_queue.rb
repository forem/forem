RSpec.shared_examples "#enqueues_on_correct_queue" do |queue_name, args|
  describe "#perform_async" do
    it "enqueues the job" do
      Sidekiq::Testing.fake!
      expect do
        described_class.perform_async(args)
      end.to change { Sidekiq::Queues[queue_name].size }.by(1)
    end
  end
end
