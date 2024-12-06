require 'unit_spec_helper'

describe Rpush::Client::Redis::Wpns::App do
  it_behaves_like 'Rpush::Client::Wpns::App'
end if redis?
