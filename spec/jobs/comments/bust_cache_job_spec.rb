require "rails_helper"

RSpec.describe Comments::BustCacheJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }
    let(:comment) { FactoryBot.create(:comment, commentable: article) }

    it "busts cache" do
      path = "#{comment.commentable.path}/comments"
      cache_buster = double
      allow(cache_buster).to receive(:bust)

      described_class.perform_now(comment.id, cache_buster)
      expect(cache_buster).to have_received(:bust).with(path).once
    end
  end
end
