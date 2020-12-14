require "rails_helper"

RSpec.describe EdgeCache::BustPodcast, type: :service do
  let(:podcast_path) { "podcast_path" }
  let(:paths) do
    [
      "/#{podcast_path}",
    ]
  end

  before do
    paths.each do |path|
      allow(described_class).to receive(:bust).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(podcast_path)

    paths.each do |path|
      expect(described_class).to have_received(:bust).with(path).once
    end
  end
end
