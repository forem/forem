require "spec_helper"

RSpec.describe Timber::Integrations::Rails::ErrorEvent do
  let(:time) { Time.utc(2016, 9, 1, 12, 0, 0) }
  let(:io) { StringIO.new }
  let(:logger) do
    logger = Timber::Logger.new(io)
    logger.level = ::Logger::INFO
    logger
  end

  around(:each) do |example|
    class RackErrorController < ActionController::Base
      layout nil

      hook_name = respond_to?(:before_action) ? "before_action" : "before_filter"
      send(hook_name) do
        raise "Boom!"
      end

      def index
        Thread.current[:_timber_context_snapshot] = Timber::CurrentContext.instance.snapshot
        render json: {}
      end

      def method_for_action(action_name)
        action_name
      end
    end

    ::RailsApp.routes.draw do
      get '/rack_error' => 'rack_error#index'
    end

    with_rails_logger(logger) do
      Timecop.freeze(time) { example.run }
    end

    Object.send(:remove_const, :RackErrorController)
  end

  describe "#process" do
    it "should log the exception" do
      allow(Benchmark).to receive(:ms).and_return(1).and_yield

      expect { dispatch_rails_request("/rack_error") }.to raise_error(RuntimeError)

      lines = clean_lines(io.string.split("\n"))

      expect(lines.length).to eq(3)

      expect(lines[0]).to include("Started GET \\\"/rack_error\\\"")
      expect(lines[1]).to include("Processing by RackErrorController#index as HTML")
      expect(lines[2]).to include("RuntimeError (Boom!)")
    end
  end

  # Remove blank lines since Rails does this to space out requests in the logs
  def clean_lines(lines)
    lines.select { |line| !line.start_with?(" @metadat") }
  end
end
