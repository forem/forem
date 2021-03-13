require "rails_helper"

RSpec.describe EdgeCache::BustSidebar, type: :service do
  let(:cache_bust) { instance_double(EdgeCache::Bust) }

  before do
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
    allow(cache_bust).to receive(:call).with("/sidebars/home").once
  end

  it "busts the cache" do
    described_class.call
    expect(cache_bust).to have_received(:call).with("/sidebars/home").once
  end
end
