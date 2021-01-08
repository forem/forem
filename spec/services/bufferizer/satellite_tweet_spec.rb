require "rails_helper"

RSpec.describe Bufferizer::SatelliteTweet, type: :service do
  describe "#call" do
    let(:user) { create(:user) }
    let(:tag) { create(:tag, buffer_profile_id_code: "test") }
    let(:article) { create(:article, user_id: user.id, tags: tag.name) }

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

    it "sends to buffer sattelite twitter" do
      allow(SiteConfig).to receive(:twitter_hashtag).and_return("#DEVCommunity")
      tweet = "test tweet #{SiteConfig.twitter_hashtag}"
      described_class.call(article, tweet, user.id)
      expect(article.last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
      expect(BufferUpdate.last.body_text).to include(" #{SiteConfig.twitter_hashtag} ##{tag.name} http")
    end
  end
end
