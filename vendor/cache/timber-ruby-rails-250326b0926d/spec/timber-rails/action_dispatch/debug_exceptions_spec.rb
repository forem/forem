require "spec_helper"

RSpec.describe Timber::Integrations::ActionDispatch::DebugExceptions do
  let(:time) { Time.utc(2016, 9, 1, 12, 0, 0) }
  let(:io) { StringIO.new }
  let(:logger) do
    logger = Timber::Logger.new(io)
    logger.level = ::Logger::DEBUG
    logger
  end

  describe "#insert!" do
    around(:each) do |example|
      class ExceptionController < ActionController::Base
        layout nil

        def index
          raise "boom"
        end

        def method_for_action(action_name)
          action_name
        end
      end

      ::RailsApp.routes.draw do
        get 'exception' => 'exception#index'
      end

      with_rails_logger(logger) do
        Timecop.freeze(time) { example.run }
      end

      Object.send(:remove_const, :ExceptionController)
    end

    it "should log an exception event once" do
      expect { dispatch_rails_request("/exception") }.to raise_error(RuntimeError)

      lines = clean_lines(io.string.split("\n"))
      expect(lines.length).to eq(3)
      expect(lines[2]).to include('RuntimeError (boom)')
      expect(lines[2]).to include('fatal')
      expect(lines[2]).to include("\"error\":{\"name\":\"RuntimeError\",\"message\":\"boom\",\"backtrace_json\":\"[")
    end

    # Remove blank lines since Rails does this to space out requests in the logs
    def clean_lines(lines)
      lines.select { |line| !line.start_with?(" @metadat") }
    end
  end
end
