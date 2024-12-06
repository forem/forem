require 'unit_spec_helper'

describe Rpush::Client::Redis::Adm::App do
  it_behaves_like 'Rpush::Client::Adm::App'
end if redis?
