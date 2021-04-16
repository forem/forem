require "rails_helper"

RSpec.describe EdgeCache::BustPage, type: :service do
  let(:cache_bust) { instance_double(EdgeCache::Bust) }
  let(:slug) { "slug" }
  let(:paths) do
    [
      "/page/#{slug}",
      "/page/#{slug}?i=i",
      "/#{slug}",
      "/#{slug}?i=i",
    ]
  end

  before do
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)

    paths.each do |path|
      allow(cache_bust).to receive(:call).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(slug)

    paths.each do |path|
      expect(cache_bust).to have_received(:call).with(path).once
    end
  end
end
