require 'unit_spec_helper'

shared_examples 'Rpush::Client::Notification' do
  let(:notification) { described_class.new }

  it 'allows assignment of many registration IDs' do
    notification.registration_ids = %w[a b]
    expect(notification.registration_ids).to eq %w[a b]
  end
end
