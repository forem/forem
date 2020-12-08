require "rails_helper"

RSpec.describe EdgeCache::BustPage, type: :service do
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
    paths.each do |path|
      allow(described_class).to receive(:bust).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(slug)

    paths.each do |path|
      expect(described_class).to have_received(:bust).with(path).once
    end
  end
end
