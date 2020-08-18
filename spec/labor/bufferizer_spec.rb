require "rails_helper"

RSpec.describe Bufferizer, type: :labor do
  let(:user) { create(:user) }
  let(:listing) { create(:listing, user_id: user.id) }
  let(:tag) { create(:tag, buffer_profile_id_code: "test") }
  let(:article) { create(:article, user_id: user.id, tags: tag.name) }

  it "sends to buffer twitter" do
    tweet = "test tweet"
    described_class.new("article", article, tweet).main_tweet!
    expect(article.last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
  end

  it "includes admin approver" do
    tweet = "test tweet"
    described_class.new("article", article, tweet, user.id).main_tweet!
    expect(BufferUpdate.last.approver_user_id).to be user.id
  end

  it "sends to buffer sattelite twitter" do
    SiteConfig.twitter_hashtag = "#DEVCommunity"
    tweet = "test tweet #{SiteConfig.twitter_hashtag}"
    described_class.new("article", article, tweet).satellite_tweet!
    expect(article.last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
    expect(BufferUpdate.last.body_text).to include(" #{SiteConfig.twitter_hashtag} ##{tag.name} http")
  end

  it "sends to buffer facebook" do
    post = "test facebook post"
    described_class.new("article", article, post, user.id).facebook_post!
    expect(article.facebook_last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
  end

  it "sends to buffer listings" do
    text = "test listing"
    described_class.new("listing", listing, text).listings_tweet!
    expect(listing.last_buffered).not_to be(nil)
  end

  it "adds linkedin social tags" do
    post = "test facebook post"
    described_class.new("article", article, post).facebook_post!
    expect(BufferUpdate.last.body_text).to include(" #programming")
    expect(BufferUpdate.last.body_text).to include(" ##{article.tag_list.first}")
  end
end
