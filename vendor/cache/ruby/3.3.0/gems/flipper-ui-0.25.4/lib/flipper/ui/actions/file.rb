require 'rack/file'
require 'flipper/ui/action'

module Flipper
  module UI
    module Actions
      class File < UI::Action
        route %r{(images|css|js)/.*\Z}

        def get
          Rack::File.new(public_path).call(request.env)
        end
      end
    end
  end
end
