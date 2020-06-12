require "spec_helper"

RSpec.describe Timber::Integrations::ActionController::LogSubscriber do
  let(:time) { Time.utc(2016, 9, 1, 12, 0, 0) }
  let(:io) { StringIO.new }
  let(:logger) do
    logger = Timber::Logger.new(io)
    logger.level = ::Logger::INFO
    logger
  end

  describe "#insert!" do
    around(:each) do |example|
      class LogSubscriberController < ActionController::Base
        layout nil

        def index
          render json: {}
        end

        def method_for_action(action_name)
          action_name
        end
      end

      ::RailsApp.routes.draw do
        get 'log_subscriber' => 'log_subscriber#index'
      end

      with_rails_logger(logger) do
        Timecop.freeze(time) { example.run }
      end

      Object.send(:remove_const, :LogSubscriberController)
    end

    it "should log a controller_call event once" do
      # Rails uses this to calculate the view runtime below
      allow(Benchmark).to receive(:ms).and_return(1).and_yield

      dispatch_rails_request("/log_subscriber?query=value")
      lines = clean_lines(io.string.split("\n"))
      expect(lines.length).to eq(3)
      expect(lines[1]).to include("Processing by LogSubscriberController#index as HTML")
      expect(lines[1]).to include('"controller_called":{"controller":"LogSubscriberController","action":"index","params_json"')
    end

    # Remove blank lines since Rails does this to space out requests in the logs
    def clean_lines(lines)
      lines.select { |line| !line.start_with?(" @metadat") }
    end
  end
end
