require "rails_helper"

# rubocop:disable RSpec/DescribeClass
# The unit under test is the side effect of loading config/initializers/trackable.rb,
# not a single class — string description is appropriate here.
RSpec.describe "config/initializers/trackable.rb" do
  let(:initializer_path) { Rails.root.join("config/initializers/trackable.rb") }

  before do
    Trackable::Registry.reset!
    load initializer_path
    Rails.application.reloader.prepare!
  end

  after { Trackable::Registry.reset! }

  it "registers Trackers::Null under :null" do
    expect(Trackable::Registry.lookup(:null)).to eq(Trackers::Null)
  end

  it "registers Trackers::CustomerioCdp under :customerio_cdp" do
    expect(Trackable::Registry.lookup(:customerio_cdp)).to eq(Trackers::CustomerioCdp)
  end
end
# rubocop:enable RSpec/DescribeClass
