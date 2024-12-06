require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Webpush::Notification do
  it_behaves_like 'Rpush::Client::Webpush::Notification'
  it_behaves_like 'Rpush::Client::ActiveRecord::Notification'
end if active_record?
