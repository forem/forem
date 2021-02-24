require "rails_helper"

RSpec.describe EdgeCache::BustSidebar, type: :service do
  let(:buster) { instance_double(EdgeCache::Buster) }

  before do
    allow(EdgeCache::Buster).to receive(:new).and_return(buster)
    allow(buster).to receive(:bust).with("/sidebars/home").once
  end

  it "busts the cache" do
    described_class.call
    expect(buster).to have_received(:bust).with("/sidebars/home").once
  end
end
