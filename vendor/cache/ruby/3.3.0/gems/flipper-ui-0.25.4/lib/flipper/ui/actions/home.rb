require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Home < UI::Action
        route %r{\A/?\Z}

        def get
          redirect_to '/features'
        end
      end
    end
  end
end
