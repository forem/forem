require "rails_helper"

RSpec.describe EdgeCache::BustTag, type: :service do
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
    paths.each do |path|
      allow(described_class).to receive(:bust).with(path).once
    end

    allow(tag).to receive(:purge).once
  end

  it "busts the cache" do
    described_class.call(tag)

    paths.each do |path|
      expect(described_class).to have_received(:bust).with(path).once
    end

    expect(tag).to have_received(:purge).once
  end
end
