require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Gcm::Notification do
  it_behaves_like 'Rpush::Client::Gcm::Notification'
  it_behaves_like 'Rpush::Client::ActiveRecord::Notification'

  subject(:notification) { described_class.new }
  let(:app) { Rpush::Gcm::App.create!(name: 'test', auth_key: 'abc') }

  it 'accepts non-booleans as a truthy value' do
    notification.dry_run = 'Not a boolean'
    expect(notification.as_json['dry_run']).to eq true
  end
end if active_record?
