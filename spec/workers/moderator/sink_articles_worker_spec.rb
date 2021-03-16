require "rails_helper"

RSpec.describe Moderator::SinkArticlesWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user_id: user.id) }

    it "returns early if user is not found" do
      allow(User).to receive(:find_by).with(id: user.id).and_return(nil)
      expect(Articles::ScoreCalcWorker)
        .not_to receive(:perform_async) # rubocop:disable RSpec/MessageSpies

      expect(described_class.new.perform(user.id)).to be_nil
    end

    it "enqueues scoring worker for user's articles" do
      article_id = article.id
      allow(Articles::ScoreCalcWorker)
        .to receive(:perform_async)
        .with(article_id)
        .once

      described_class.new.perform(user.id)
    end
  end
end
