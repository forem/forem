require 'rails_helper'

RSpec.describe 'Example App' do
  it "has ActiveRecord defined" do
    expect(defined?(ActiveRecord)).to be
  end
end
