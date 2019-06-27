require "rails_helper"

RSpec.describe Bufferizer do
  let(:user) { create(:user) }
  let(:listing) { create(:classified_listing, user_id: user.id) }
  let(:article) { create(:article, user_id: user.id) }

  it "sends to buffer twitter" do
    tweet = "test tweet"
    described_class.new("article", article, tweet).main_tweet!
    expect(article.last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
  end

  it "sends to buffer facebook" do
    post = "test facebook post"
    described_class.new("article", article, post).facebook_post!
    expect(article.facebook_last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
  end

  it "sends to buffer listings" do
    text = "test listing"
    described_class.new("listing", listing, text).listings_tweet!
    expect(listing.last_buffered).not_to be(nil)
  end
end
