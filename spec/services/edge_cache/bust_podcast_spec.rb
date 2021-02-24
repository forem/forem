require "rails_helper"

RSpec.describe EdgeCache::BustPodcast, type: :service do
  let(:buster) { instance_double(EdgeCache::Buster) }
  let(:podcast_path) { "podcast_path" }
  let(:paths) do
    [
      "/#{podcast_path}",
    ]
  end

  before do
    allow(EdgeCache::Buster).to receive(:new).and_return(buster)

    paths.each do |path|
      allow(buster).to receive(:bust).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(podcast_path)

    paths.each do |path|
      expect(buster).to have_received(:bust).with(path).once
    end
  end
end
