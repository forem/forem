require 'rails_helper'

RSpec.describe 'Example App' do
  it "does not have ActiveRecord defined" do
    expect(defined?(ActiveRecord)).not_to be
  end
end
