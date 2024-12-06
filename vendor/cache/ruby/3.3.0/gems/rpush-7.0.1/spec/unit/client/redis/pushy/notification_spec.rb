require 'unit_spec_helper'

describe Rpush::Client::Redis::Pushy::Notification do
  it_behaves_like 'Rpush::Client::Pushy::Notification'
end if redis?
