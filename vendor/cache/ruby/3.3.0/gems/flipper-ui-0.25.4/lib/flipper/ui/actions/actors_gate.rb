require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class ActorsGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/actors/?\Z}

        def get
          feature = flipper[feature_name]
          @feature = Decorators::Feature.new(feature)

          breadcrumb 'Home', '/'
          breadcrumb 'Features', '/features'
          breadcrumb @feature.key, "/features/#{@feature.key}"
          breadcrumb 'Add Actor'

          view_response :add_actor
        end

        def post
          read_only if Flipper::UI.configuration.read_only

          feature = flipper[feature_name]
          value = params['value'].to_s.strip
          values = value.split(UI.configuration.actors_separator).map(&:strip).uniq

          if values.empty?
            error = "#{value.inspect} is not a valid actor value."
            redirect_to("/features/#{feature.key}/actors?error=#{error}")
          end

          values.each do |value|
            actor = Flipper::Actor.new(value)

            case params['operation']
            when 'enable'
              feature.enable_actor actor
            when 'disable'
              feature.disable_actor actor
            end
          end

          redirect_to("/features/#{feature.key}")
        end
      end
    end
  end
end
