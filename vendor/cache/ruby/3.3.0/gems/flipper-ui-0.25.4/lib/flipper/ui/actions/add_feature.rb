require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class AddFeature < UI::Action
        route %r{\A/features/new/?\Z}

        def get
          read_only if Flipper::UI.configuration.read_only

          unless Flipper::UI.configuration.feature_creation_enabled
            status 403

            breadcrumb 'Home', '/'
            breadcrumb 'Features', '/features'
            breadcrumb 'Noooooope'

            halt view_response(:feature_creation_disabled)
          end

          breadcrumb 'Home', '/'
          breadcrumb 'Features', '/features'
          breadcrumb 'Add'

          view_response :add_feature
        end
      end
    end
  end
end
