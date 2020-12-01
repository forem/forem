# This spec needs to be run before `rails_helper` is loaded to check the issue
RSpec.describe "Verify issue rspec/rspec-rails#1355" do
  it "passes" do
    expect(1).to eq 1
  end
end
require 'rails_helper'
