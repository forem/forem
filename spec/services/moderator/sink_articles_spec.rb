require "rails_helper"

RSpec.describe Moderator::SinkArticles, type: :service do
  let(:user) { create(:user) }

  describe "#call" do
    it "enqueues the associated worker with this user id" do
      allow(Moderator::SinkArticlesWorker)
        .to receive(:perform_async)
        .with(user.id)
        .once

      described_class.call(user.id)
    end
  end
end
