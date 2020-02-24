require "rails_helper"

VCR_OPTIONS = {
  cassette_name: "twitter_fetch_status",
  allow_playback_repeats: true
}.freeze

RSpec.describe Tweet, type: :model, vcr: VCR_OPTIONS do
  let(:tweet_id) { "1018911886862057472" }

  it "fetches a tweet" do
    tweet = described_class.fetch(tweet_id)
    expect(tweet.class).to eq(described_class)
  end

  it "renders processed text" do
    tweet = described_class.fetch(tweet_id)
    expect(tweet.processed_text).not_to be_nil
  end
end
