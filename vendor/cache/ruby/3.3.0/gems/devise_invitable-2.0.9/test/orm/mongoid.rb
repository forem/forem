Mongoid.configure do |config|
  if Mongoid::VERSION < '3.0.0'
    config.master = Mongo::Connection.new('127.0.0.1', 27017).db('devise_invitable-test-suite')
  else
    config.connect_to('devise_invitable-test-suite')
    config.use_utc = true
    config.include_root_in_json = true
  end
end

class ActiveSupport::TestCase
  setup do
    if Mongoid::VERSION < '3.0.0'
      User.delete_all
      Admin.delete_all
    else
      Mongoid.purge!
    end
  end
end
