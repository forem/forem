require "spec_helper"

RSpec.describe Timber::Integrations::Rack::HTTPEvents do
  let(:time) { Time.utc(2016, 9, 1, 12, 0, 0) }
  let(:io) { StringIO.new }
  let(:logger) do
    logger = Timber::Logger.new(io)
    logger.level = ::Logger::INFO
    logger
  end

  around(:each) do |example|
    class RackHttpController < ActionController::Base
      layout nil

      def index
        Thread.current[:_timber_context_snapshot] = Timber::CurrentContext.instance.snapshot
        render json: {}
      end

      def method_for_action(action_name)
        action_name
      end
    end

    ::RailsApp.routes.draw do
      get '/rack_http' => 'rack_http#index'
    end

    with_rails_logger(logger) do
      Timecop.freeze(time) { example.run }
    end

    Object.send(:remove_const, :RackHttpController)
  end

  describe "#process" do
    it "should log the events" do
      allow(Benchmark).to receive(:ms).and_return(1).and_yield

      dispatch_rails_request("/rack_http")

      lines = clean_lines(io.string.split("\n"))
      expect(lines.length).to eq(3)

      expect(lines[0]).to include("Started GET \\\"/rack_http\\\"")
      expect(lines[1]).to include("Processing by RackHttpController#index as HTML")
      expect(lines[2]).to include("Completed 200 OK in 0.0ms")
    end

    context "with the route silenced" do
      around(:each) do |example|
        described_class.silence_request = lambda do |rack_env, rack_request|
          rack_request.path == "/rack_http"
        end

        example.run

        described_class.silence_request = nil
      end

      it "should silence the logs" do
        allow(Benchmark).to receive(:ms).and_return(1).and_yield

        dispatch_rails_request("/rack_http")

        lines = clean_lines(io.string.split("\n"))
        expect(lines.length).to eq(0)
      end
    end

    context "collapsed into a single event" do
      around(:each) do |example|
        described_class.collapse_into_single_event = true

        example.run

        described_class.collapse_into_single_event = nil
      end

      it "should silence the logs" do
        allow(Benchmark).to receive(:ms).and_return(1).and_yield

        dispatch_rails_request("/rack_http")

        lines = clean_lines(io.string.split("\n"))
        expect(lines.length).to eq(2)

        expect(lines[0]).to include("Processing by RackHttpController#index as HTML")
        expect(lines[1]).to include("GET /rack_http completed with 200 OK in 0.0ms")
      end
    end
  end

  # Remove blank lines since Rails does this to space out requests in the logs
  def clean_lines(lines)
    lines.select { |line| !line.start_with?(" @metadat") }
  end
end
