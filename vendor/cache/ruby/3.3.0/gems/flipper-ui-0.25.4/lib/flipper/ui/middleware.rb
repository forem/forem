require 'rack'
require 'flipper/ui/action_collection'

# Require all actions automatically.
Pathname(__FILE__).dirname.join('actions').each_child(false) do |name|
  require "flipper/ui/actions/#{name}"
end

module Flipper
  module UI
    class Middleware
      def initialize(app, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper')
        @flipper = options.fetch(:flipper) { Flipper }

        @action_collection = ActionCollection.new

        # UI
        @action_collection.add UI::Actions::AddFeature
        @action_collection.add UI::Actions::ActorsGate
        @action_collection.add UI::Actions::GroupsGate
        @action_collection.add UI::Actions::BooleanGate
        @action_collection.add UI::Actions::PercentageOfTimeGate
        @action_collection.add UI::Actions::PercentageOfActorsGate
        @action_collection.add UI::Actions::Feature
        @action_collection.add UI::Actions::Features

        # Static Assets/Files
        @action_collection.add UI::Actions::File

        # Catch all redirect to features
        @action_collection.add UI::Actions::Home
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        request = Rack::Request.new(env)
        action_class = @action_collection.action_for_request(request)

        if action_class.nil?
          @app.call(env)
        else
          flipper = env.fetch(@env_key) { Flipper }
          action_class.run(flipper, request)
        end
      end
    end
  end
end
