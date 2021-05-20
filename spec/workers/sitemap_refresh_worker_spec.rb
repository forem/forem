require "rails_helper"

RSpec.describe SitemapRefreshWorker, type: :woker do
  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    let(:worker) { subject }
    let(:mock_task) { instance_double(Rake::Task, invoke: true) }

    before do
      allow(Rails.application).to receive(:load_tasks)
      allow(Rake::Task).to receive(:[]).and_return(mock_task)
    end

    it "runs sitemap:refresh:no_ping Rake task locally" do
      allow(ForemInstance).to receive(:local?).and_return(true)

      worker.perform

      expect(Rake::Task).to have_received(:[]).with("sitemap:refresh:no_ping")
    end

    it "runs sitemap:refresh Rake task on regular installations" do
      allow(ForemInstance).to receive(:local?).and_return(false)

      worker.perform

      expect(Rake::Task).to have_received(:[]).with("sitemap:refresh")
    end
  end
end
