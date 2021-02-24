require "rails_helper"

RSpec.describe EdgeCache::BustEvents, type: :service do
  let(:buster) { instance_double(EdgeCache::Buster) }
  let(:paths) do
    [
      "/events",
      "/events?i=i",
    ]
  end

  before do
    allow(EdgeCache::Buster).to receive(:new).and_return(buster)
    paths.each do |path|
      allow(buster).to receive(:bust).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call

    paths.each do |path|
      expect(buster).to have_received(:bust).with(path).once
    end
  end
end
