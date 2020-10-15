require "rails_helper"

RSpec.describe Articles::RssReaderWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "updates RssReader articles" do
      allow(RssReader).to receive(:get_all_articles)
      worker.perform
      expect(RssReader).to have_received(:get_all_articles).with(force: false)
    end
  end
end
