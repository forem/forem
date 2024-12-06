# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      class Initialized < Base
        def process
          # @todo Temporarily removed textDocument/codeAction
          host.register_capabilities %w[
            textDocument/completion
            textDocument/hover
            textDocument/signatureHelp
            textDocument/formatting
            textDocument/documentSymbol
            textDocument/definition
            textDocument/references
            textDocument/rename
            textDocument/prepareRename
            textDocument/foldingRange
            textDocument/documentHighlight
            workspace/symbol
          ]
        end
      end
    end
  end
end
