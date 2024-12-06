require 'unit_spec_helper'

describe Rpush::Client::Redis::Adm::Notification do
  it_behaves_like 'Rpush::Client::Adm::Notification'
end if redis?
