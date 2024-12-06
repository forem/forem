require 'unit_spec_helper'

describe Rpush::Client::Redis::Gcm::Notification do
  it_behaves_like 'Rpush::Client::Gcm::Notification'
end if redis?
