require "rails_helper"

RSpec.describe EdgeCache::BustEvents, type: :service do
  let(:cache_bust) { instance_double(EdgeCache::Bust) }
  let(:paths) do
    [
      "/events",
      "/events?i=i",
    ]
  end

  before do
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
    paths.each do |path|
      allow(cache_bust).to receive(:call).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call

    paths.each do |path|
      expect(cache_bust).to have_received(:call).with(path).once
    end
  end
end
