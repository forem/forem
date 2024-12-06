require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Webpush::App do
  it_behaves_like 'Rpush::Client::Webpush::App'
  it_behaves_like 'Rpush::Client::ActiveRecord::App'
end if active_record?
