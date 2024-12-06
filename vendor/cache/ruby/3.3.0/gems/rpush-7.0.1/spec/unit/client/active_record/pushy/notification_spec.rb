require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Pushy::Notification do
  it_behaves_like 'Rpush::Client::Pushy::Notification'
  it_behaves_like 'Rpush::Client::ActiveRecord::Notification'
end if active_record?
