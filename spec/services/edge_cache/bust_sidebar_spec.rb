require "rails_helper"

RSpec.describe EdgeCache::BustSidebar, type: :service do
  before do
    allow(described_class).to receive(:bust).with("/sidebars/home").once
  end

  it "busts the cache" do
    described_class.call
    expect(described_class).to have_received(:bust).with("/sidebars/home").once
  end
end
