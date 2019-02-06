require "rails_helper"

RSpec.describe Articles::ResaveJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        Articles::ResaveJob.perform_later([1, 2])
      end.to have_enqueued_job.with([1, 2]).on_queue("articles_resave")
    end

    it "busts cache" do
      article = create(:article)
      path = article.path

      cache_buster = double
      allow(cache_buster).to receive(:bust)

      Articles::ResaveJob.perform_now([article.id], cache_buster)
      expect(cache_buster).to have_received(:bust).with(path).once
      expect(cache_buster).to have_received(:bust).with(path + "?i=i").once
    end
  end
end
