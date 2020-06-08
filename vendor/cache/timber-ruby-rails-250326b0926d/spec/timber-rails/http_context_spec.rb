require "spec_helper"

RSpec.describe Timber::Integrations::Rack::HTTPContext do
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
    it "should set the context" do
      allow(Benchmark).to receive(:ms).and_return(1).and_yield

      dispatch_rails_request("/rack_http")
      http_context = Thread.current[:_timber_context_snapshot][:http]

      expect(http_context).to eq({:host => "example.org", :method=>"GET", :path=>"/rack_http", :remote_addr=>"123.456.789.10", :request_id=>"unique-request-id-1234"})

      lines = clean_lines(io.string.split("\n"))
      expect(lines.length).to eq(3)
      lines.each do |line|
        expect(line).to include("\"http\":{\"host\":\"example.org\",\"method\":\"GET\",\"path\":\"/rack_http\",\"remote_addr\":\"123.456.789.10\",\"request_id\":\"unique-request-id-1234\"}")
      end
    end
  end

  # Remove blank lines since Rails does this to space out requests in the logs
  def clean_lines(lines)
    lines.select { |line| !line.start_with?(" @metadat") }
  end
end
