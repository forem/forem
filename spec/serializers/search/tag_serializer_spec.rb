require "rails_helper"

RSpec.describe Search::TagSerializer do
  let(:tag) { create(:tag) }

  it "serializes a Tag" do
    data_hash = described_class.new(tag).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(:id, :name, :hotness_score, :supported, :short_summary, :rules_html)
  end
end
