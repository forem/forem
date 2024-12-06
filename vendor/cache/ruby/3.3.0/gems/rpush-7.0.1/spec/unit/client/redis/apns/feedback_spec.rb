require 'unit_spec_helper'

describe Rpush::Client::Redis::Apns::Feedback do
  it_behaves_like 'Rpush::Client::Apns::Feedback'
end if redis?
