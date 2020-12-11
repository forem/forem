require 'rails_helper'

RSpec.describe "Using rspec-mocks with models" do
  it "supports stubbing class methods on models" do
    allow(Widget).to receive(:all).and_return(:any_stub)
    expect(Widget.all).to be :any_stub
  end

  it "supports stubbing attribute methods on models" do
    a_widget = Widget.new
    allow(a_widget).to receive(:name).and_return("Any Stub")

    expect(a_widget.name).to eq "Any Stub"
  end
end
