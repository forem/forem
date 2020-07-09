require "spec_helper"

RSpec.describe Timber::Integrations::Rails::RackLogger do
  describe described_class::InstanceMethods do
    let(:time) { Time.utc(2016, 9, 1, 12, 0, 0) }
    let(:io) { StringIO.new }
    let(:logger) do
      logger = Timber::Logger.new(io)
      logger.level = ::Logger::INFO
      logger
    end

    around(:each) do |example|
      class RailsRackLoggerController < ActionController::Base
        layout nil

        def index
          render json: {}
        end

        def method_for_action(action_name)
          action_name
        end
      end

      ::RailsApp.routes.draw do
        get '/rails_rack_logger' => 'rails_rack_logger#index'
      end

      with_rails_logger(logger) do
        Timecop.freeze(time) { example.run }
      end

      Object.send(:remove_const, :RailsRackLoggerController)
    end

    describe "#started_request_message" do
      it "should mute the default rails logs" do
        allow(::Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production")) # Rails 3.2.X

        dispatch_rails_request("/rails_rack_logger")

        lines = clean_lines(io.string.split("\n"))
        expect(lines.length).to eq(3)
        expect(lines[0]).to include("Started GET \\\"/rails_rack_logger\\\"")
        expect(lines[1]).to include("Processing by RailsRackLoggerController#index as HTML")
        expect(lines[2]).to include("Completed 200 OK in 0.0ms")
      end
    end
  end

  # Remove blank lines since Rails does this to space out requests in the logs
  def clean_lines(lines)
    lines.select { |line| !line.start_with?(" @metadat") }
  end
end
