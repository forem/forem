require "rails_helper"

RSpec.describe EdgeCache::BustListings, type: :service do
  let(:listing) { create(:listing) }
  let(:cache_bust) { instance_double(EdgeCache::Bust) }

  let(:paths) do
    [
      "/listings",
      "/listings?i=i",
      "/listings/#{listing.category}/#{listing.slug}",
      "/listings/#{listing.category}/#{listing.slug}?i=i",
      "/listings/#{listing.category}",
    ]
  end

  before do
    allow(listing).to receive(:purge_all)
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)

    paths.each do |path|
      allow(cache_bust).to receive(:call).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(listing)

    expect(listing).to have_received(:purge_all)

    paths.each do |path|
      expect(cache_bust).to have_received(:call).with(path).once
    end
  end
end
