require 'spec_helper'
require 'rails'

# load all shared example files
Dir["./spec/unit/**/shared/**/*.rb"].sort.each { |f| require f }

def unit_example?(metadata)
  metadata[:file_path] =~ %r{spec/unit}
end

RSpec.configure do |config|
  config.before(:each) do
    Modis.with_connection do |redis|
      redis.keys('rpush:*').each { |key| redis.del(key) }
    end if redis?

    if active_record? && unit_example?(self.class.metadata)
      connection = ActiveRecord::Base.connection
      connection.begin_transaction joinable: false
    end
  end

  config.after(:each) do
    if active_record? && unit_example?(self.class.metadata)
      connection = ActiveRecord::Base.connection
      connection.rollback_transaction if connection.transaction_open?
    end
  end
end
