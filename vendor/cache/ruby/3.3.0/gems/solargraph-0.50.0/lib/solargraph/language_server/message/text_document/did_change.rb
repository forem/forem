# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidChange < Base
          def process
            host.change params
          end
        end
      end
    end
  end
end
