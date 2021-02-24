require "rails_helper"

RSpec.describe EdgeCache::BustTag, type: :service do
  let(:buster) { instance_double(EdgeCache::Buster) }
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
    allow(EdgeCache::Buster).to receive(:new).and_return(buster)

    paths.each do |path|
      allow(buster).to receive(:bust).with(path).once
    end

    allow(tag).to receive(:purge).once
  end

  it "busts the cache" do
    described_class.call(tag)

    paths.each do |path|
      expect(buster).to have_received(:bust).with(path).once
    end

    expect(tag).to have_received(:purge).once
  end
end
