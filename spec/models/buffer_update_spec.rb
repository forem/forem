require "rails_helper"

RSpec.describe BufferUpdate, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  it "creates update" do
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(described_class.all.size).to eq(1)
  end

  it "does not allow duplicate updates" do
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(described_class.all.size).to eq(1)
  end

  it "does not allow duplicate updates if the first one was a little while ago" do
    b1 = described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    b1.update_column(:created_at, 5.minutes.ago)
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(described_class.all.size).to eq(2)
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(described_class.all.size).to eq(2)
    described_class.buff!(article.id, "twitter_buffer_text yoyo", "CODE", "twitter")
    expect(described_class.all.size).to eq(3)
  end

  it "allows same text across different social platforms" do
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "facebook")
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter")
    expect(described_class.all.size).to eq(2)
  end

  it "allows same text across different tags" do
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter", 1)
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter", 2)
    expect(described_class.all.size).to eq(2)
  end

  it "allows same text across different articles with the same tag" do
    described_class.buff!(article.id, "twitter_buffer_text", "CODE", "twitter", 1)
    described_class.buff!(create(:article).id, "twitter_buffer_text", "CODE", "twitter", 1)
    expect(described_class.all.size).to eq(2)
  end
end
