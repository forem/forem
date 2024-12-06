require 'unit_spec_helper'

describe Rpush::Client::Redis::Webpush::App do
  it_behaves_like 'Rpush::Client::Webpush::App'
end if redis?
