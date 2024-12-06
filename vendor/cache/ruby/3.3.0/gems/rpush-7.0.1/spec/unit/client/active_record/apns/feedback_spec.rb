require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Apns::Feedback do
  it_behaves_like 'Rpush::Client::Apns::Feedback'
end if active_record?
