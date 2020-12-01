module RSpec
  module Matchers
    def fail(&block)
      raise_error(RSpec::Mocks::MockExpectationError, &block)
    end

    def fail_with(*args, &block)
      raise_error(RSpec::Mocks::MockExpectationError, *args, &block)
    end

    def fail_including(*snippets)
      raise_error(
        RSpec::Mocks::MockExpectationError,
        a_string_including(*snippets)
      )
    end
  end
end
