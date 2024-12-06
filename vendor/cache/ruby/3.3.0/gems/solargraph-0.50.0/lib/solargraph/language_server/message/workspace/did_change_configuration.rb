# frozen_string_literal: true

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeConfiguration < Solargraph::LanguageServer::Message::Base
    def process
      return unless params['settings']
      update = params['settings']['solargraph']
      host.configure update
      register_from_options
    end

    private

    def register_from_options
      y = []
      n = []
      (host.options['completion'] ? y : n).push('textDocument/completion')
      (host.options['hover'] ? y : n).push('textDocument/hover', 'textDocument/signatureHelp')
      (host.options['autoformat'] ? y : n).push('textDocument/onTypeFormatting')
      (host.options['formatting'] ? y : n).push('textDocument/formatting')
      (host.options['symbols'] ? y : n).push('textDocument/documentSymbol', 'workspace/symbol')
      (host.options['definitions'] ? y : n).push('textDocument/definition')
      (host.options['references'] ? y : n).push('textDocument/references')
      (host.options['folding'] ? y : n).push('textDocument/folding')
      (host.options['highlights'] ? y : n).push('textDocument/documentHighlight')
      host.register_capabilities y
      host.unregister_capabilities n
    end
  end
end
