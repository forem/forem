require "rails_helper"

RSpec.describe RSpecRetryPolicy do
  describe "retry options" do
    it "retries JavaScript examples without the global exception filter" do
      expect(described_class::JS_OPTIONS).to eq(retry: 3, exceptions_to_retry: [])
    end

    it "retries explicitly flaky examples without the global exception filter" do
      expect(described_class::FLAKY_OPTIONS).to eq(retry: 5, exceptions_to_retry: [])
    end
  end

  describe ".compose_callbacks" do
    it "runs every callback in order with the RSpec example group context" do
      callback_host = Class.new do
        attr_reader :events

        def initialize
          @events = []
        end
      end.new
      example = Object.new
      first_callback = proc { |received_example| events << [:first, received_example] }
      second_callback = proc { |received_example| events << [:second, received_example] }

      callback = described_class.compose_callbacks(first_callback, nil, second_callback)
      callback_host.instance_exec(example, &callback)

      expect(callback_host.events).to eq([[:first, example], [:second, example]])
    end
  end
end
