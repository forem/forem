require "rails_helper"

RSpec.describe EdgeCache::BustTag, type: :service do
  let(:cache_bust) { instance_double(EdgeCache::Bust) }
  let(:tag) { create(:tag) }
  let(:paths) do
    [
      "/t/#{tag.name}",
      "/t/#{tag.name}?i=i",
      "/t/#{tag.name}/?i=i",
      "/t/#{tag.name}/",
      "/tags",
    ]
  end

  before do
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)

    paths.each do |path|
      allow(cache_bust).to receive(:call).with(path).once
    end

    allow(tag).to receive(:purge).once
  end

  it "busts the cache" do
    described_class.call(tag)

    paths.each do |path|
      expect(cache_bust).to have_received(:call).with(path).once
    end

    expect(tag).to have_received(:purge).once
  end
end
