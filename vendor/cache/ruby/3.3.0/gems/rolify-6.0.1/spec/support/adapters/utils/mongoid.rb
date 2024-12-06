require 'mongoid'

def mongoid_major_version
  Mongoid::VERSION.split('.').first.to_i
end

def mongoid_config
  "spec/support/adapters/mongoid_#{mongoid_major_version}.yml"
end

def load_mongoid_config
  Mongoid.load!(mongoid_config, :test)
end
