require "rails_helper"

RSpec.describe EdgeCache::Commentable::Bust, type: :service do
  let(:commentable) { create(:article) }
  let(:cache_buster) { double }

  before do
    allow(cache_buster).to receive(:bust_comment)
    allow(cache_buster).to receive(:bust).with("#{commentable.path}/comments")
  end

  it "busts the cache" do
    described_class.call(commentable, cache_buster)
    expect(cache_buster).to have_received(:bust_comment).with(commentable).once
    expect(cache_buster).to have_received(:bust).with("#{commentable.path}/comments").once
  end

  it "indexes the commentable" do
    allow(commentable).to receive(:index!)
    described_class.call(commentable, cache_buster)
    expect(commentable).to have_received(:index!).once
  end

  it "indexes commentable to Elasticsearch" do
    allow(commentable).to receive(:index_to_elasticsearch_inline)
    described_class.call(commentable, cache_buster)
    expect(commentable).to have_received(:index_to_elasticsearch_inline).once
  end
end
