require 'unit_spec_helper'

describe Rpush::Client::Redis::App do
  it_behaves_like 'Rpush::Client::App'
end if redis?
