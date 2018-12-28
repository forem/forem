require "rails_helper"

RSpec.describe BufferUpdate, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  it "creates update" do
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(BufferUpdate.all.size).to eq(1)
  end

  it "does not allow duplicate updates" do
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(BufferUpdate.all.size).to eq(1)
  end

  it "does not allow duplicate updates if the first one was a little while ago" do
    b1 = BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    b1.update_column(:created_at, 5.minutes.ago)
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(BufferUpdate.all.size).to eq(2)
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(BufferUpdate.all.size).to eq(2)
    BufferUpdate.buff!(article.id, "twitter_buffer_text yoyo", "CODE", "twitter")
    expect(BufferUpdate.all.size).to eq(3)
  end

  it "allows same text across different social platforms" do
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "facebook")
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(BufferUpdate.all.size).to eq(2)
  end

  it "allows same text across different tags" do
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter", 1)
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter", 2)
    expect(BufferUpdate.all.size).to eq(2)
  end

  it "allows same text across different articles with the same tag" do
    BufferUpdate.buff!(article.id, "twitter_buffer_text", "CODE", "twitter", 1)
    BufferUpdate.buff!(create(:article).id, "twitter_buffer_text", "CODE", "twitter", 1)
    expect(BufferUpdate.all.size).to eq(2)
  end
end
