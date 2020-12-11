module RSpec
  module Mocks
    module ExampleMethods
    end

    def self.configuration; RSpec::Core::NullReporter; end
  end
end
