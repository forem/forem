require "rails_helper"

RSpec.describe EdgeCache::BustListings, type: :service do
  let(:listing) { create(:listing) }

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

    paths.each do |path|
      allow(described_class).to receive(:bust).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(listing)

    expect(listing).to have_received(:purge_all)

    paths.each do |path|
      expect(described_class).to have_received(:bust).with(path).once
    end
  end
end
