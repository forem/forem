require "rails_helper"

RSpec.describe Bufferizer::MainTweet, type: :service do
  describe "#call" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user_id: user.id) }

    context "when article is nil" do
      it "doesn't raise an error" do
        tweet = "test tweet"
        expect { described_class.call(nil, tweet, user.id) }.not_to raise_error
      end
    end

    context "when tweet is nil" do
      it "doesn't raise an error" do
        expect { described_class.call(article, nil, user.id) }.not_to raise_error
      end
    end

    context "when admin_id is nil" do
      it "doesn't raise an error" do
        tweet = "test tweet"
        expect { described_class.call(article, tweet, nil) }.not_to raise_error
      end
    end

    it "sends to buffer twitter" do
      tweet = "test tweet"
      described_class.call(article, tweet, user.id)
      expect(article.last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
    end

    it "includes admin approver" do
      tweet = "test tweet"
      described_class.call(article, tweet, user.id)
      expect(BufferUpdate.last.approver_user_id).to be user.id
    end
  end
end
