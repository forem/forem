require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Wpns::App do
  it_behaves_like 'Rpush::Client::Wpns::App'
  it_behaves_like 'Rpush::Client::ActiveRecord::App'
end if active_record?
