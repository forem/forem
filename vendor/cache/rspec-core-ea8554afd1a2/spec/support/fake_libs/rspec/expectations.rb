module RSpec
  module Expectations
    MultipleExpectationsNotMetError = Class.new(Exception)
  end

  module Matchers
    def self.configuration; RSpec::Core::NullReporter; end
  end
end
