require "rails_helper"

RSpec.describe "config/initializers/trackable.rb" do
  before do
    Trackable::Registry.register(:null, Trackers::Null)
    Trackable::Registry.register(:customerio_cdp, Trackers::CustomerioCdp)
  end

  it "registers Trackers::Null under :null" do
    expect(Trackable::Registry.lookup(:null)).to eq(Trackers::Null)
  end

  it "registers Trackers::CustomerioCdp under :customerio_cdp" do
    expect(Trackable::Registry.lookup(:customerio_cdp)).to eq(Trackers::CustomerioCdp)
  end
end
