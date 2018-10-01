require "rails_helper"

RSpec.describe Bufferizer do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  it "sends to buffer twitter" do
    tweet = "test tweet"
    described_class.new(article, tweet).main_teet!
    expect(article.last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
  end

  it "sends to buffer facebook" do
    post = "test facebook post"
    described_class.new(article, post).facebook_post!
    expect(article.facebook_last_buffered.utc.to_i).to be > 2.minutes.ago.to_i
  end
end
