module ActionDispatch
  module Routing
    class RouteSet
      class NamedRouteCollection
        class UrlHelper
          def initialize(route, options, route_name)
            @options      = options
            # Hack to prevent :locale being passed as the first missing positional argument,
            # since we cannot explicitly set default value of :locale param in routes
            # due to a Rails bug since 4.0 on default value of optional scope.
            # As this might involve some bigger architecture issue of ActionDispatch(?),
            # an official fix is not likely to come anytime soon.
            # See: https://github.com/rails/rails/issues/12178
            # See: https://github.com/rails/rails/pull/39582
            segkeys       = route.segment_keys.uniq
            @segment_keys = segkeys[0] == :locale ? segkeys[1..] : segkeys
            @route        = route
            @route_name   = route_name
          end
        end
      end
    end
  end
end
