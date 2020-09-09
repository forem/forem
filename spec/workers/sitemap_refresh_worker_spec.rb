require "rails_helper"

RSpec.describe SitemapRefreshWorker, type: :woker do
  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    let(:worker) { subject }

    it "runs sitemap refresh rake task" do
      allow(Rails.application).to receive(:load_tasks)
      mock_task = instance_double(Rake::Task, invoke: true)
      allow(Rake::Task).to receive(:[]).and_return(mock_task)
      worker.perform
      expect(Rake::Task).to have_received(:[]).with("sitemap:refresh")
    end
  end
end
