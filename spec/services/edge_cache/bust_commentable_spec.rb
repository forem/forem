require "rails_helper"

RSpec.describe EdgeCache::BustCommentable, type: :service do
  let(:buster) { instance_double(EdgeCache::Buster) }
  let(:commentable) { create(:article) }

  before do
    allow(EdgeCache::BustComment).to receive(:call)
    allow(EdgeCache::Buster).to receive(:new).and_return(buster)
    allow(buster).to receive(:bust)
  end

  it "busts the cache" do
    described_class.call(commentable)
    expect(EdgeCache::BustComment).to have_received(:call).with(commentable).once
    expect(buster).to have_received(:bust).with("#{commentable.path}/comments").once
  end

  it "indexes commentable to Elasticsearch" do
    allow(commentable).to receive(:index_to_elasticsearch_inline)
    described_class.call(commentable)
    expect(commentable).to have_received(:index_to_elasticsearch_inline).once
  end
end
