require 'unit_spec_helper'

describe Rpush::Client::Redis::Wns::BadgeNotification do
  it_behaves_like 'Rpush::Client::Wns::BadgeNotification'
end if redis?
