require 'active_record'

def establish_connection
  ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database => ":memory:"
  )
end

def extend_rspec_with_activerecord_specific_matchers
  RSpec::Matchers::BuiltIn::OperatorMatcher.register(ActiveRecord::Relation, '=~', RSpec::Matchers::BuiltIn::ContainExactly)
end
