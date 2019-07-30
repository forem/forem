require "rails_helper"

vcr_option = {
  cassette_name: "twitter_gem",
  allow_playback_repeats: "true"
}

RSpec.describe Tweet, type: :model, vcr: vcr_option do
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
