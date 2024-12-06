require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Adm::App do
  it_behaves_like 'Rpush::Client::Adm::App'
  it_behaves_like 'Rpush::Client::ActiveRecord::App'
end if active_record?
