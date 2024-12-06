require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Pushy::App do
  it_behaves_like 'Rpush::Client::Pushy::App'
  it_behaves_like 'Rpush::Client::ActiveRecord::App'
end if active_record?
