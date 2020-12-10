require "rails_helper"

RSpec.describe EdgeCache::BustCommentable, type: :service do
  let(:commentable) { create(:article) }

  before do
    allow(EdgeCache::BustComment).to receive(:call)
    allow(described_class).to receive(:bust).with("#{commentable.path}/comments")
  end

  it "busts the cache" do
    described_class.call(commentable)
    expect(EdgeCache::BustComment).to have_received(:call).with(commentable).once
    expect(described_class).to have_received(:bust).with("#{commentable.path}/comments").once
  end

  it "indexes commentable to Elasticsearch" do
    allow(commentable).to receive(:index_to_elasticsearch_inline)
    described_class.call(commentable)
    expect(commentable).to have_received(:index_to_elasticsearch_inline).once
  end
end
