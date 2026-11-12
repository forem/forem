require "rails_helper"

RSpec.describe EdgeCache::BustTag, type: :service do
  let(:tag) { create(:tag) }
  let(:paths) do
    [
      "/t/#{tag.name}",
      "/t/#{tag.name}/",
      "/tags",
    ]
  end

  before do
    tag
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "purges the tag, tags table, and supported_tags surrogate keys in a single call" do
    described_class.call(tag)

    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      [tag.record_key, Tag.table_key, Tag::SUPPORTED_TAGS_SURROGATE_KEY],
      fallback_paths: paths,
    ).once
  end
end
