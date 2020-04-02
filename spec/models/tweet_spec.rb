require "rails_helper"

RSpec.describe Tweet, type: :model, vcr: VCR_OPTIONS[:twitter_fetch_status] do
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
