require 'unit_spec_helper'

describe Rpush::Client::Redis::Gcm::App do
  it_behaves_like 'Rpush::Client::Gcm::App'
end if redis?
