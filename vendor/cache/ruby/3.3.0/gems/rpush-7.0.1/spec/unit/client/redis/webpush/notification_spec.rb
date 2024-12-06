require 'unit_spec_helper'

describe Rpush::Client::Redis::Webpush::Notification do
  it_behaves_like 'Rpush::Client::Webpush::Notification'
end if redis?
