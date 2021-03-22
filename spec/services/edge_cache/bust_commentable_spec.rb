require "rails_helper"

RSpec.describe EdgeCache::BustCommentable, type: :service do
  let(:cache_bust) { instance_double(EdgeCache::Bust) }
  let(:commentable) { create(:article) }

  before do
    allow(EdgeCache::BustComment).to receive(:call)
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
    allow(cache_bust).to receive(:call)
  end

  it "busts the cache" do
    described_class.call(commentable)
    expect(EdgeCache::BustComment).to have_received(:call).with(commentable).once
    expect(cache_bust).to have_received(:call).with("#{commentable.path}/comments").once
  end

  it "indexes commentable to Elasticsearch" do
    allow(commentable).to receive(:index_to_elasticsearch_inline)
    described_class.call(commentable)
    expect(commentable).to have_received(:index_to_elasticsearch_inline).once
  end
end
