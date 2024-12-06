require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Wns::BadgeNotification do
  it_behaves_like 'Rpush::Client::Wns::BadgeNotification'
end if active_record?
