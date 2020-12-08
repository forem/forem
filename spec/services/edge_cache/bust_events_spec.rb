require "rails_helper"

RSpec.describe EdgeCache::BustEvents, type: :service do
  let(:paths) do
    [
      "/events",
      "/events?i=i",
    ]
  end

  before do
    paths.each do |path|
      allow(described_class).to receive(:bust).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call

    paths.each do |path|
      expect(described_class).to have_received(:bust).with(path).once
    end
  end
end
