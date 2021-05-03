require "rails_helper"

RSpec.describe Search::ArticleSerializer do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:tag) { create(:tag, name: "ama", bg_color_hex: "#f3f3f3", text_color_hex: "#cccccc") }
  let(:article) { create(:article, user: user, organization: organization, tags: tag.name) }

  it "serializes an article" do
    stub_const("FlareTag::FLARE_TAG_IDS_HASH", { "ama" => tag.id })
    data_hash = described_class.new(article).serializable_hash.dig(:data, :attributes)
    user_data = Search::NestedUserSerializer.new(user).serializable_hash.dig(:data, :attributes)
    expect(data_hash[:user]).to eq(user_data)
    expect(data_hash.dig(:organization, :id)).to eq(organization.id)
    expect(data_hash.dig(:flare_tag_hash, :name)).to eq(tag.name)
    expect(data_hash.keys).to include(:id, :body_text, :hotness_score)
  end

  it "correctly serializes video duration in minutes when video_duration_in_seconds is nil" do
    data_hash = described_class.new(article).serializable_hash.dig(:data, :attributes)
    expect(data_hash[:video_duration_in_minutes]).to eq(0)
  end

  it "correctly serializes video duration in minutes when video_duration_in_seconds is not nil" do
    duration = (1.hour + 1.minute).to_i
    allow(article).to receive(:video_duration_in_seconds).and_return(duration)
    data_hash = described_class.new(article).serializable_hash.dig(:data, :attributes)
    expect(data_hash[:video_duration_in_minutes]).to eq(61)
  end
end
