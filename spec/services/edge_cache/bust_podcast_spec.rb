require "rails_helper"

RSpec.describe EdgeCache::BustPodcast, type: :service do
  let(:cache_bust) { instance_double(EdgeCache::Bust) }
  let(:podcast_path) { "podcast_path" }
  let(:paths) do
    [
      "/#{podcast_path}",
    ]
  end

  before do
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)

    paths.each do |path|
      allow(cache_bust).to receive(:call).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(podcast_path)

    paths.each do |path|
      expect(cache_bust).to have_received(:call).with(path).once
    end
  end
end
