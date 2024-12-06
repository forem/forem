require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Wpns::Notification do
  it_behaves_like 'Rpush::Client::Wpns::Notification'
  it_behaves_like 'Rpush::Client::ActiveRecord::Notification'
end if active_record?
