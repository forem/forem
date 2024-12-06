require 'unit_spec_helper'

describe Rpush::Client::Redis::Notification do
  it_behaves_like 'Rpush::Client::Notification'
end if redis?
