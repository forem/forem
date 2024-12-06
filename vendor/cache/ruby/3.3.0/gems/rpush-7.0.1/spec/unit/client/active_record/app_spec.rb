require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::App do
  it_behaves_like 'Rpush::Client::App'
end if active_record?
