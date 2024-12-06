# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidOpen < Base
          def process
            host.open params['textDocument']['uri'], params['textDocument']['text'], params['textDocument']['version']
          end
        end
      end
    end
  end
end
