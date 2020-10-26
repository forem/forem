require "rails_helper"

RSpec.describe BufferUpdate, type: :model do
  let(:article) { create(:article) }
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  describe "validations" do
    describe "builtin validations" do
      subject { described_class.buff!(article.id, "twitter_buffer_text") }

      it { is_expected.to belong_to(:approver_user).optional }
      it { is_expected.to belong_to(:composer_user).optional }
      it { is_expected.to belong_to(:tag).optional }
    end
  end

  it "creates update" do
    described_class.buff!(article.id, "twitter_buffer_text")
    expect(described_class.all.size).to eq(1)
  end

  it "does not allow duplicate updates" do
    described_class.buff!(article.id, "twitter_buffer_text")
    described_class.buff!(article.id, "twitter_buffer_text")
    expect(described_class.all.size).to eq(1)
  end

  it "does not allow duplicate updates if the first one was a little while ago" do
    b1 = described_class.buff!(article.id, "twitter_buffer_text")
    b1.update_column(:created_at, 5.minutes.ago)
    described_class.buff!(article.id, "twitter_buffer_text")
    expect(described_class.all.size).to eq(2)
    described_class.buff!(article.id, "twitter_buffer_text")
    expect(described_class.all.size).to eq(2)
    described_class.buff!(article.id, "twitter_buffer_text yoyo")
    expect(described_class.all.size).to eq(3)
  end

  it "allows same text across different social platforms" do
    described_class.buff!(article.id, "twitter_buffer_text", social_service_name: "facebook")
    described_class.buff!(article.id, "twitter_buffer_text")
    expect(described_class.all.size).to eq(2)
  end

  it "allows same text across different tags" do
    described_class.buff!(article.id, "twitter_buffer_text", tag_id: tag1.id)
    described_class.buff!(article.id, "twitter_buffer_text", tag_id: tag2.id)
    expect(described_class.all.size).to eq(2)
  end

  it "allows same text across different articles with the same tag" do
    described_class.buff!(article.id, "twitter_buffer_text", tag_id: tag1.id)
    described_class.buff!(create(:article).id, "twitter_buffer_text", tag_id: tag1.id)
    expect(described_class.all.size).to eq(2)
  end

  it "does not allow more than 3 suggestions" do
    Array.new(3) do |i|
      described_class.buff!(article.id, "twitter_buffer_text_#{i}")
    end
    invalid_buffer = described_class.buff!(article.id, "twitter_buffer_text_4")
    expect(described_class.all.size).to eq(3)
    expect(invalid_buffer.errors.full_messages.first).to include("already has multiple suggestions")
  end
end
