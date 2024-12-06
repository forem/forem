module Nesty
  module NestedError
    attr_reader :nested, :raw_backtrace

    def initialize(msg = nil, nested = $!)
      super(msg)
      @nested = nested
    end

    def set_backtrace(backtrace)
      @raw_backtrace = backtrace
      if nested
        backtrace = backtrace - nested_raw_backtrace
        backtrace += ["#{nested.backtrace.first}: #{nested.message} (#{nested.class.name})"]
        backtrace += nested.backtrace[1..-1] || []
      end
      super(backtrace)
    end

    private

    def nested_raw_backtrace
      nested.respond_to?(:raw_backtrace) ? nested.raw_backtrace : nested.backtrace
    end
  end
end
