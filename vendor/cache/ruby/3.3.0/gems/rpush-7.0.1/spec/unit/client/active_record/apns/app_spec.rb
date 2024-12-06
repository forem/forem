require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Apns::App do
  it_behaves_like 'Rpush::Client::Apns::App'
  it_behaves_like 'Rpush::Client::ActiveRecord::App'
end if active_record?
