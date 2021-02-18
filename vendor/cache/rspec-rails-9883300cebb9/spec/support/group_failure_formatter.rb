module RSpec::Rails::TestSupport
  class FailureReporter
    def initialize
      @exceptions = []
    end
    attr_reader :exceptions

    def example_failed(example)
      @exceptions << example.exception
    end

    def method_missing(name, *_args, &_block)
    end
  end

  def failure_reporter
    @failure_reporter ||= FailureReporter.new
  end
end

RSpec.configure do |config|
  config.include RSpec::Rails::TestSupport
end
