require 'rails_helper'

RSpec.describe Tweet, type: :model do
  it "fetches a tweet" do
    tweet = Tweet.fetch("STUBBED_TWEET_ID")
    expect(tweet.class.name).to eq("Tweet")
  end
  it "renders processed text" do
    tweet = Tweet.fetch("STUBBED_TWEET_ID")
    expect(tweet.processed_text).to include("<br/>") # because there is a \n in the tweet
  end
end
