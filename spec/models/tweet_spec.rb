require "rails_helper"

RSpec.describe Tweet, type: :model, vcr: true do
  let(:tweet_id) { "1018911886862057472" }
  let(:tweet_reply_id) { "1242938461784608770" }

  it "fetches a tweet" do
    VCR.use_cassette("twitter_fetch_status") do
      tweet = described_class.fetch(tweet_id)
      expect(tweet).to be_a(described_class)
    end
  end

  it "renders processed text" do
    VCR.use_cassette("twitter_fetch_status") do
      tweet = described_class.fetch(tweet_id)
      expect(tweet.processed_text).not_to be_nil
    end
  end

  describe "reply ids" do
    it "correctly saves in_reply_to_user_id_code" do
      VCR.use_cassette("twitter_fetch_reply") do
        tweet = described_class.fetch(tweet_reply_id)
        expect(tweet.in_reply_to_user_id_code).to eq("45042829")
      end
    end

    it "correctly saves in_reply_to_status_id_code" do
      VCR.use_cassette("twitter_fetch_reply") do
        tweet = described_class.fetch(tweet_reply_id)
        expect(tweet.in_reply_to_status_id_code).to eq("1242837746315669505")
      end
    end
  end
end
