# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      class MethodNotImplemented < Base
        def process
          # This method ignores optional requests, e.g., any method that
          # starts with `$/`.
        end
      end
    end
  end
end
